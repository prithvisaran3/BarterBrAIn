const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();

const db = admin.firestore();

// TODO: Set SendGrid API key using: firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
// Or set via environment variable: SENDGRID_API_KEY
const SENDGRID_API_KEY = functions.config().sendgrid?.key || process.env.SENDGRID_API_KEY;

// SendGrid setup (optional, falls back to debug mode if not configured)
let sgMail = null;
if (SENDGRID_API_KEY) {
  sgMail = require('@sendgrid/mail');
  sgMail.setApiKey(SENDGRID_API_KEY);
}

/**
 * Send OTP to user's email for verification
 * 
 * Request body: { email: string, universityId: string }
 * Response: { success: boolean, message: string }
 */
exports.sendOtp = functions.https.onCall(async (data, context) => {
  try {
    const { email, universityId } = data;

    // Validate inputs
    if (!email || !universityId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and university ID are required'
      );
    }

    // Validate email format
    if (!email.includes('@') || !email.toLowerCase().endsWith('.edu')) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid .edu email address'
      );
    }

    // Get university from Firestore
    const universityDoc = await db.collection('universities').doc(universityId).get();
    
    if (!universityDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'University not found'
      );
    }

    const university = universityDoc.data();
    const emailDomain = email.split('@')[1].toLowerCase();

    // Validate email domain matches university
    if (!university.domains || !university.domains.includes(emailDomain)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email domain does not match selected university'
      );
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Hash OTP before storing
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');
    
    // Hash email for document ID
    const emailHash = crypto.createHash('sha256').update(email.toLowerCase()).digest('hex');
    
    // Store OTP in Firestore with 5 minute expiry
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 5 * 60 * 1000)
    );
    
    await db.collection('emailOtps').doc(emailHash).set({
      otpHash: otpHash,
      expiresAt: expiresAt,
      tries: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send OTP via email
    const emailSent = await sendOtpEmail(email, otp, university.name);
    
    if (!emailSent && !SENDGRID_API_KEY) {
      // Debug mode: store plain OTP in a separate collection for testing
      await db.collection('emailOtpsDebug').doc(email.toLowerCase()).set({
        otp: otp,
        email: email,
        universityId: universityId,
        expiresAt: expiresAt,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`DEBUG MODE: OTP for ${email}: ${otp}`);
    }

    return {
      success: true,
      message: 'OTP sent successfully',
      debug: !emailSent ? 'SendGrid not configured, OTP stored in emailOtpsDebug collection' : null,
    };

  } catch (error) {
    console.error('Error sending OTP:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send OTP. Please try again.'
    );
  }
});

/**
 * Verify OTP submitted by user
 * 
 * Request body: { email: string, otp: string }
 * Response: { success: boolean, message: string, customToken?: string }
 */
exports.verifyOtp = functions.https.onCall(async (data, context) => {
  try {
    const { email, otp } = data;

    // Validate inputs
    if (!email || !otp) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Email and OTP are required'
      );
    }

    if (otp.length !== 6 || !/^\d{6}$/.test(otp)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid OTP format'
      );
    }

    // Hash email to get document ID
    const emailHash = crypto.createHash('sha256').update(email.toLowerCase()).digest('hex');
    
    // Get OTP document
    const otpDoc = await db.collection('emailOtps').doc(emailHash).get();
    
    if (!otpDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'No OTP found for this email. Please request a new one.'
      );
    }

    const otpData = otpDoc.data();
    
    // Check if OTP has expired
    if (otpData.expiresAt.toDate() < new Date()) {
      await otpDoc.ref.delete();
      throw new functions.https.HttpsError(
        'deadline-exceeded',
        'OTP has expired. Please request a new one.'
      );
    }

    // Check attempt limit
    if (otpData.tries >= 3) {
      await otpDoc.ref.delete();
      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Too many failed attempts. Please request a new OTP.'
      );
    }

    // Hash submitted OTP and compare
    const submittedOtpHash = crypto.createHash('sha256').update(otp).digest('hex');
    
    if (submittedOtpHash !== otpData.otpHash) {
      // Increment tries
      await otpDoc.ref.update({
        tries: admin.firestore.FieldValue.increment(1),
      });
      
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Invalid OTP. ${2 - otpData.tries} attempts remaining.`
      );
    }

    // OTP is valid - delete it
    await otpDoc.ref.delete();
    
    // Also clean up debug entry if exists
    try {
      await db.collection('emailOtpsDebug').doc(email.toLowerCase()).delete();
    } catch (e) {
      // Ignore if doesn't exist
    }

    return {
      success: true,
      message: 'Email verified successfully',
    };

  } catch (error) {
    console.error('Error verifying OTP:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to verify OTP. Please try again.'
    );
  }
});

/**
 * Helper function to send OTP email via SendGrid or Nodemailer
 * Returns true if email was sent, false if in debug mode
 */
async function sendOtpEmail(email, otp, universityName) {
  const subject = 'Verify Your BarterBrAIn Account';
  const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif; line-height: 1.6; color: #000; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; padding: 40px 0; }
        .logo { width: 80px; height: 80px; background: #0ABAB5; border-radius: 20px; margin: 0 auto 20px; display: flex; align-items: center; justify-content: center; color: white; font-size: 40px; }
        .title { font-size: 28px; font-weight: bold; color: #0ABAB5; margin: 0; }
        .otp-box { background: #F2F2F7; border-radius: 12px; padding: 30px; text-align: center; margin: 30px 0; }
        .otp-code { font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #0ABAB5; margin: 20px 0; }
        .info { color: #8E8E93; font-size: 14px; text-align: center; margin-top: 30px; }
        .footer { text-align: center; margin-top: 40px; padding-top: 20px; border-top: 1px solid #E5E5EA; color: #8E8E93; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">🔄</div>
          <h1 class="title">BarterBrAIn</h1>
        </div>
        <p>Hello,</p>
        <p>You're one step away from joining <strong>${universityName}</strong> on BarterBrAIn!</p>
        <div class="otp-box">
          <p style="margin: 0; color: #8E8E93;">Your verification code is:</p>
          <div class="otp-code">${otp}</div>
          <p style="margin: 0; color: #8E8E93; font-size: 14px;">This code expires in 5 minutes</p>
        </div>
        <p>If you didn't request this code, please ignore this email.</p>
        <p class="info">
          BarterBrAIn is a campus-exclusive marketplace for verified students to trade items sustainably.
        </p>
        <div class="footer">
          <p>© 2025 BarterBrAIn. Campus Exchange, Elevated.</p>
        </div>
      </div>
    </body>
    </html>
  `;

  const textContent = `
Your BarterBrAIn verification code is: ${otp}

This code expires in 5 minutes.

If you didn't request this code, please ignore this email.

- BarterBrAIn Team
  `;

  // Try SendGrid first
  if (sgMail && SENDGRID_API_KEY) {
    try {
      await sgMail.send({
        to: email,
        from: 'noreply@barterbrain.com', // TODO: Update with your verified sender
        subject: subject,
        text: textContent,
        html: htmlContent,
      });
      console.log(`OTP email sent to ${email} via SendGrid`);
      return true;
    } catch (error) {
      console.error('SendGrid error:', error);
      // Fall through to debug mode
    }
  }

  // Debug mode: email not sent, will be stored in emailOtpsDebug
  console.log(`SendGrid not configured. OTP will be stored in emailOtpsDebug collection.`);
  return false;
}

/**
 * Clean up expired OTPs (runs every hour)
 */
exports.cleanupExpiredOtps = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  const now = admin.firestore.Timestamp.now();
  
  // Clean up emailOtps
  const expiredOtps = await db.collection('emailOtps')
    .where('expiresAt', '<', now)
    .get();
  
  const batch = db.batch();
  expiredOtps.docs.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
  
  // Clean up emailOtpsDebug
  const expiredDebugOtps = await db.collection('emailOtpsDebug')
    .where('expiresAt', '<', now)
    .get();
  
  const debugBatch = db.batch();
  expiredDebugOtps.docs.forEach(doc => debugBatch.delete(doc.ref));
  await debugBatch.commit();
  
  console.log(`Cleaned up ${expiredOtps.size + expiredDebugOtps.size} expired OTPs`);
  return null;
});

