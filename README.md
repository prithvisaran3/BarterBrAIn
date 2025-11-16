# BarterBrAIn

**Campus-wide peer-to-peer trading platform with AI-powered price suggestions**

BarterBrAIn is a Flutter mobile application that enables verified university students to trade items with each other seamlessly. The platform combines real-time messaging, AI-driven product valuation, and secure payment integration to create a trusted marketplace within university communities.

---

## 🚀 Features

### For Students
- ✅ **Verified Community**: Only `.edu` email addresses
- ✅ **Smart Pricing**: AI suggests fair market value
- ✅ **Real-time Chat**: WhatsApp-like messaging with emojis and images
- ✅ **Secure Payments**: Integrated with Capital One Nessie API
- ✅ **Trade Matching**: Find products within your price range
- ✅ **Trade History**: Track all your exchanges

### Tech Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **State Management**: GetX
- **UI**: Cupertino Native (iOS-inspired widgets)
- **AI**: Google Gemini API
- **Payments**: Capital One Nessie API

---

## 📦 Quick Start

### Prerequisites
- Flutter SDK (latest stable)
- Firebase CLI
- Xcode (for iOS)
- Node.js (for Cloud Functions)

### Installation

```bash
# Clone the repository
git clone https://github.com/prithvisaran3/BarterBrAIn.git
cd BarterBrAIn

# Install dependencies
flutter pub get

# Setup Firebase
firebase login
firebase use barterbrain-1254a

# Install Cloud Functions dependencies
cd functions
npm install
cd ..

# Run the app
flutter run
```

---

## 🏗️ Project Structure

```
BarterBrAIn/
├── lib/                      # Flutter app source code
│   ├── main.dart            # App entry point
│   ├── core/                # Constants, theme, configs
│   ├── models/              # Data models
│   ├── controllers/         # GetX controllers
│   ├── services/            # Business logic services
│   ├── views/               # UI screens
│   └── widgets/             # Reusable components
├── assets/                  # Images, data files
├── ios/                     # iOS project files
├── functions/               # Firebase Cloud Functions
├── firebase.json            # Firebase configuration
├── firestore.rules          # Firestore security rules
├── storage.rules            # Storage security rules
└── pubspec.yaml             # Flutter dependencies
```

---

## 🔥 Firebase Services

### Authentication
- Email/Password with OTP verification
- `.edu` domain validation
- Cloud Functions for email sending

### Firestore Collections
- `users` - User profiles
- `universities` - University data
- `products` - Listed items
- `chats` - Chat conversations
- `messages` - Chat messages (subcollection)
- `trades` - Trade transactions
- `notifications` - In-app notifications

### Storage
- Product images
- Profile photos
- Chat images

---

## 📚 Documentation

- [Integration Verification](./INTEGRATION_VERIFICATION.md)
- [Testing Guide](./TEST_PRODUCTS_AND_CHAT.md)
- [Performance Optimizations](./PERFORMANCE_OPTIMIZATIONS.md)
- [Physical Device Setup](./PHYSICAL_DEVICE_SETUP.md)
- [AI Integration Guide](./MOBILE_INTEGRATION_GUIDE.md)
- [GitHub Setup](./GITHUB_SETUP.md)

---

## 🧪 Testing

```bash
# Run tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Check for issues
flutter analyze
```

---

## 🚀 Deployment

### Mobile App

```bash
# iOS
flutter build ios --release

# Android (future)
flutter build apk --release
```

### Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### Firestore & Storage Rules

```bash
firebase deploy --only firestore:rules,storage,firestore:indexes
```

---

## 🤝 Contributing

This is a hackathon project. Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

---

## 📄 License

[MIT License](LICENSE)

---

## 👥 Team

- **Mobile Development**: Flutter + Firebase
- **AI/ML Services**: Python + Gemini API
- **Backend**: Firebase Cloud Functions
- **Payment Integration**: Capital One Nessie API

---

## 🙏 Acknowledgments

- Firebase for backend infrastructure
- Google Gemini for AI capabilities
- Capital One for Nessie API
- Flutter team for the amazing framework

---

**Built with ❤️ for university students**

