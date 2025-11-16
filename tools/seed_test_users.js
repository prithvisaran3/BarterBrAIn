/**
 * Create test users with verified .edu status
 * 
 * Usage:
 * 1. Make sure you're logged in: firebase login
 * 2. Make sure Firebase project is set: firebase use YOUR_PROJECT_ID
 * 3. Install dependencies: npm install
 * 4. Run: node tools/seed_test_users.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
try {
  const serviceAccount = require('../service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.log('Service account not found, trying default credentials...');
  admin.initializeApp();
}

const db = admin.firestore();
const auth = admin.auth();

const testUsers = [
  {
    email: 'test1@georgetown.edu',
    password: 'TestPass123!',
    firstName: 'John',
    lastName: 'Doe',
    gender: 'Male',
    major: 'Computer Science',
    universityId: 'georgetown',
  },
  {
    email: 'test2@stanford.edu',
    password: 'TestPass123!',
    firstName: 'Jane',
    lastName: 'Smith',
    gender: 'Female',
    major: 'Business Administration',
    universityId: 'stanford',
  },
  {
    email: 'test3@mit.edu',
    password: 'TestPass123!',
    firstName: 'Alex',
    lastName: 'Johnson',
    gender: 'Non-binary',
    major: 'Electrical Engineering',
    universityId: 'mit',
  },
];

async function seedTestUsers() {
  try {
    console.log('👥 Starting test user creation...');
    
    for (const userData of testUsers) {
      try {
        // Create Auth user
        const userRecord = await auth.createUser({
          email: userData.email,
          password: userData.password,
          displayName: `${userData.firstName} ${userData.lastName}`,
          emailVerified: true,
        });
        
        console.log(`✅ Created Auth user: ${userData.email}`);
        
        // Create Firestore document
        await db.collection('users').doc(userRecord.uid).set({
          firstName: userData.firstName,
          lastName: userData.lastName,
          displayName: `${userData.firstName} ${userData.lastName}`,
          email: userData.email,
          profilePhotoUrl: null,
          gender: userData.gender,
          major: userData.major,
          universityId: userData.universityId,
          isVerifiedEdu: true,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        console.log(`✅ Created Firestore document for: ${userData.email}`);
        console.log(`   UID: ${userRecord.uid}`);
        console.log(`   Password: ${userData.password}`);
        console.log('');
        
      } catch (error) {
        if (error.code === 'auth/email-already-exists') {
          console.log(`⚠️  User already exists: ${userData.email}`);
        } else {
          console.error(`❌ Error creating user ${userData.email}:`, error.message);
        }
      }
    }
    
    console.log('🎉 Test user seeding completed!');
    console.log('\nTest Credentials:');
    testUsers.forEach(user => {
      console.log(`${user.email} / ${user.password}`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding test users:', error);
    process.exit(1);
  }
}

seedTestUsers();

