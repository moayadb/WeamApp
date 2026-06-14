# وئام — Weam iOS & Android App

A Flutter-based mobile application for the Weam family counselor AI system. Available for both iOS and Android.

## Features

- 💬 Arabic chat interface (RTL support)
- 🤖 Integration with n8n AI Agent
- 💾 Local conversation storage
- 🌙 Dark/Light mode toggle
- 🔔 Push notifications
- 📱 Responsive design for all screen sizes
- 🔒 Complete privacy (all data stored locally)

## Prerequisites

- Flutter SDK (3.0+)
- Dart SDK
- iOS: Xcode 14+ (Mac required)
- Android: Android Studio + NDK
- GitHub account
- Apple Developer Account ($99/year)
- Google Play Developer Account ($25 one-time)

## Building Locally

### 1. Clone the repository

```bash
git clone <repository-url>
cd WeamApp
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

**iOS:**
```bash
flutter run -d iPhone
```

**Android:**
```bash
flutter run -d Android
```

## Publishing to App Stores

This project is set up with **Codemagic** for automated builds and publishing.

### Setup

1. Create a GitHub repository and push this code
2. Connect to Codemagic: https://codemagic.io
3. Authorize with GitHub account
4. Configure API keys in Codemagic:
   - **Apple App Store Connect API Key**
   - **Google Play Service Account JSON**

### Automated Build & Publish

Codemagic will automatically:
- Build iOS and Android apps
- Sign with production certificates
- Submit to App Store and Google Play
- Deploy automatically on new releases

### Manual Build

**iOS (Requires Mac):**
```bash
flutter build ios --release
```

**Android:**
```bash
flutter build appbundle --release
```

## Firebase Setup

Push notifications require Firebase configuration:

1. Create Firebase project: https://console.firebase.google.com
2. Download `GoogleService-Info.plist` (iOS)
3. Download `google-services.json` (Android)
4. Place in respective directories:
   - iOS: `ios/Runner/GoogleService-Info.plist`
   - Android: `android/app/google-services.json`

## Configuration

Edit webhook URL in `lib/services/webhook_service.dart`:

```dart
static const String webhookUrl = 'https://your-n8n-webhook-url';
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── chat_screen.dart     # Main chat UI
├── widgets/
│   ├── message_bubble.dart  # Message display
│   └── conversation_list.dart
├── services/
│   ├── webhook_service.dart # n8n integration
│   ├── storage_service.dart # Local storage
│   └── notification_service.dart # Push notifications
├── models/
│   ├── message.dart         # Message model
│   └── conversation.dart    # Conversation model
└── providers/
    └── theme_provider.dart  # Dark/Light mode
```

## Support

For issues or questions, contact: mouayad.balloul@gmail.com

## License

Proprietary - Weam Project
