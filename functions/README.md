# BarterBrAIn Cloud Functions

Firebase Cloud Functions for email OTP verification and backend logic.

## Functions

### `sendOtp`
Sends a 6-digit OTP to the user's email for verification.

**Parameters:**
- `email` (string): User's .edu email address
- `universityId` (string): Selected university ID

**Returns:**
- `success` (boolean): Whether OTP was sent
- `message` (string): Status message
- `debug` (string, optional): Debug information if SendGrid not configured

### `verifyOtp`
Verifies the OTP submitted by the user.

**Parameters:**
- `email` (string): User's email address
- `otp` (string): 6-digit OTP code

**Returns:**
- `success` (boolean): Whether OTP is valid
- `message` (string): Status message

### `cleanupExpiredOtps`
Scheduled function that runs every hour to clean up expired OTPs.

## Setup

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure SendGrid (Optional)

For production email sending:

```bash
firebase functions:config:set sendgrid.key="YOUR_SENDGRID_API_KEY"
```

Or set environment variable:
```bash
export SENDGRID_API_KEY="YOUR_SENDGRID_API_KEY"
```

**Note:** If SendGrid is not configured, OTPs will be stored in the `emailOtpsDebug` Firestore collection for testing.

### 3. Update Sender Email

In `index.js`, update the `from` field in the SendGrid email:
```javascript
from: 'noreply@barterbrain.com', // TODO: Update with your verified sender
```

## Development

### Run Locally with Emulator

```bash
cd ..
firebase emulators:start --only functions,firestore,auth
```

### View Logs

```bash
firebase functions:log
```

## Deployment

```bash
# Deploy all functions
npm run deploy

# Or from project root
firebase deploy --only functions
```

## Testing

### Test sendOtp (Emulator)

```bash
curl -X POST http://localhost:5001/YOUR_PROJECT_ID/us-central1/sendOtp \
  -H "Content-Type: application/json" \
  -d '{"data":{"email":"test@georgetown.edu","universityId":"georgetown"}}'
```

### Test verifyOtp (Emulator)

```bash
curl -X POST http://localhost:5001/YOUR_PROJECT_ID/us-central1/verifyOtp \
  -H "Content-Type: application/json" \
  -d '{"data":{"email":"test@georgetown.edu","otp":"123456"}}'
```

## Security

- OTPs are hashed using SHA-256 before storage
- OTPs expire after 5 minutes
- Maximum 3 verification attempts per OTP
- Email domains are validated against university records
- All inputs are validated and sanitized

## Debug Mode

When SendGrid is not configured:
- OTPs are stored in `emailOtpsDebug` collection
- Access via Firebase Console or Emulator UI
- Document ID is the email address (lowercase)
- Contains: `otp`, `email`, `universityId`, `expiresAt`, `createdAt`

