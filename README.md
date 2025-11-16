# BarterBrAIn

**Campus-wide peer-to-peer trading platform with AI-powered price suggestions**

BarterBrAIn is a mobile application that enables verified university students to trade items with each other seamlessly. The platform combines real-time messaging, AI-driven product valuation, and secure payment integration to create a trusted marketplace within university communities.

---

## 🚀 Project Structure

This monorepo contains two main components:

```
BarterBrAIn/
├── BarterBrAIN-app/     # Flutter mobile application
└── BarterBrAIn-ai/      # AI/ML services for price prediction
```

### 📱 BarterBrAIN-app
The Flutter mobile application with:
- iOS-inspired liquid glass UI
- Firebase Authentication (.edu email verification)
- Real-time chat and messaging
- Product listing and discovery
- AI-powered price suggestions
- Capital One Nessie API payment integration
- In-app notifications

**Tech Stack**:
- Flutter (Dart)
- Firebase (Auth, Firestore, Storage, Functions)
- GetX (State Management)
- Cupertino Native (iOS widgets)

[View App README →](./BarterBrAIN-app/README.md)

---

### 🤖 BarterBrAIn-ai
AI/ML services for:
- Product metadata valuation
- Price prediction based on condition, age, brand
- Image analysis for product verification
- Market trend analysis

**Tech Stack**:
- Python
- Google Gemini API
- Firebase Cloud Functions
- TensorFlow/PyTorch (future)

[View AI README →](./BarterBrAIn-ai/README.md)

---

## 🎯 Key Features

### For Students
- ✅ **Verified Community**: Only `.edu` email addresses
- ✅ **Smart Pricing**: AI suggests fair market value
- ✅ **Real-time Chat**: WhatsApp-like messaging with emojis and images
- ✅ **Secure Payments**: Integrated with Capital One Nessie API
- ✅ **Trade Matching**: Find products within your price range
- ✅ **Trade History**: Track all your exchanges

### For Developers
- ✅ **Clean Architecture**: MVC pattern with GetX
- ✅ **Type Safety**: Full null safety in Dart
- ✅ **Real-time**: Firestore streaming for instant updates
- ✅ **Security**: Comprehensive Firebase security rules
- ✅ **Scalable**: Modular design for easy feature additions
- ✅ **Well Documented**: Extensive inline and markdown docs

---

## 🏃 Quick Start

### Prerequisites
- Flutter SDK (latest stable)
- Firebase CLI
- Xcode (for iOS)
- Node.js (for Cloud Functions)

### Clone and Setup
```bash
# Clone the repository
git clone https://github.com/yourusername/BarterBrAIn.git
cd BarterBrAIn

# Setup Flutter app
cd BarterBrAIN-app
flutter pub get
firebase login
firebase use --add
flutter run

# Setup AI services (coming soon)
cd ../BarterBrAIn-ai
# Follow AI README
```

---

## 📚 Documentation

### App Documentation
- [Integration Verification](./BarterBrAIN-app/INTEGRATION_VERIFICATION.md)
- [Testing Guide](./BarterBrAIN-app/TEST_PRODUCTS_AND_CHAT.md)
- [Performance Optimizations](./BarterBrAIN-app/PERFORMANCE_OPTIMIZATIONS.md)
- [Physical Device Setup](./BarterBrAIN-app/PHYSICAL_DEVICE_SETUP.md)
- [AI Integration Guide](./BarterBrAIN-app/MOBILE_INTEGRATION_GUIDE.md)

### API Documentation
- Coming soon

---

## 🏗️ Architecture

### Mobile App Architecture
```
lib/
├── main.dart                  # App entry point
├── core/                      # App-wide utilities
│   ├── constants.dart
│   └── theme.dart
├── models/                    # Data models
│   ├── user_model.dart
│   ├── product_model.dart
│   ├── chat_model.dart
│   └── trade_model.dart
├── controllers/               # GetX controllers
│   └── auth_controller.dart
├── services/                  # Business logic
│   ├── firebase_service.dart
│   ├── chat_service.dart
│   ├── ai_service.dart
│   └── nessie_api_service.dart
├── views/                     # UI screens
│   ├── auth/
│   ├── main/
│   ├── products/
│   ├── chat/
│   └── trade/
└── widgets/                   # Reusable components
```

### AI Services Architecture
Coming soon

---

## 🔥 Firebase Services

### Authentication
- Email/Password with OTP verification
- .edu domain validation
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

## 🧪 Testing

```bash
# Run Flutter tests
cd BarterBrAIN-app
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
cd BarterBrAIN-app

# iOS
flutter build ios --release

# Android (future)
flutter build apk --release
```

### Cloud Functions
```bash
cd BarterBrAIN-app/functions
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

## 📞 Support

For questions or issues:
- Open a GitHub issue
- Check the documentation
- Review the test guides

---

**Built with ❤️ for university students**


