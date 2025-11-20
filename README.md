# 🔐 Authenticator

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-green.svg)

**A secure, modern, and feature-rich TOTP Authenticator app built with Flutter**

[Features](#-features) • [Installation](#-installation) • [Architecture](#-architecture) • [Security](#-security) • [Contributing](#-contributing)

</div>

---

## 📱 Overview

Authenticator is a professional-grade Time-based One-Time Password (TOTP) authentication app that provides secure two-factor authentication (2FA) for your accounts. Built with Flutter, it offers a beautiful, intuitive interface with enterprise-level security features.

### ✨ Key Highlights

- 🔒 **Bank-Level Security**: AES-256 encryption with secure key derivation
- 🎨 **Modern UI/UX**: Beautiful animations with dark/light theme support
- 📷 **QR Code Scanner**: Quick setup with camera-based QR scanning
- 🔐 **Biometric Auth**: Fingerprint and face recognition support
- 💾 **Secure Storage**: Encrypted local database with SQLite
- ⚡ **Real-time Codes**: Auto-refresh TOTP codes with countdown timers
- 🎯 **Zero Dependencies**: No internet required, fully offline

---

## 🚀 Features

### Core Functionality
- ✅ Generate TOTP codes (RFC 6238 compliant)
- ✅ QR code scanning for quick account setup
- ✅ Manual account entry with custom parameters
- ✅ Real-time code generation with countdown timer
- ✅ Copy codes to clipboard with one tap
- ✅ Search and filter accounts
- ✅ Account management (add, edit, delete)

### Security Features
- 🔐 AES-256-GCM encryption for all sensitive data
- 🔑 PBKDF2 key derivation with bcrypt password hashing
- 🔒 Biometric authentication (fingerprint/face ID)
- 🛡️ Secure storage using platform keychain
- 🔄 Automatic data migration with integrity checks
- 🚫 No cloud sync - your data stays on your device

### User Experience
- 🎨 Beautiful Material Design 3 UI
- 🌓 Dark and light theme support
- ✨ Smooth Lottie animations
- 📊 Clean and intuitive interface
- ⚡ Fast performance with optimized rendering
- 🎯 Accessibility support

---

## 📦 Installation

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.8.1 or higher)
- Android Studio / Xcode (for mobile development)
- Git

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/premprashantjha/Authenticator.git
   cd Authenticator_poc
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate app icons and splash screen**
   ```bash
   flutter pub run flutter_launcher_icons
   flutter pub run flutter_native_splash:create
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── animations/          # Lottie animation controllers
├── app/                 # App configuration and theme
│   ├── app.dart        # Main app widget
│   └── theme.dart      # Theme definitions
├── models/             # Data models
│   └── account.dart    # Account model
├── services/           # Business logic layer
│   ├── account_service.dart       # Account CRUD operations
│   ├── database_service.dart      # SQLite database management
│   ├── encryption_service.dart    # Encryption/decryption
│   ├── migration_service.dart     # Data migration
│   ├── secure_storage_service.dart # Secure key storage
│   ├── theme_service.dart         # Theme management
│   └── totp_service.dart          # TOTP code generation
├── view/               # UI screens
│   ├── add_account_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── qr_scan_screen.dart
│   ├── settings_screen.dart
│   └── splash_screen.dart
├── view_models/        # State management
│   └── account_view_model.dart
├── widgets/            # Reusable components
│   └── custom_snackbar.dart
└── main.dart           # App entry point
```

### Design Patterns

- **MVVM Architecture**: Separation of UI and business logic
- **Provider Pattern**: State management across the app
- **Service Layer**: Encapsulated business logic
- **Repository Pattern**: Abstract data access
- **Dependency Injection**: Loose coupling between components

### Tech Stack

| Category | Technology |
|----------|-----------|
| Framework | Flutter 3.8.1+ |
| Language | Dart 3.8.1+ |
| State Management | Provider |
| Database | SQLite (sqflite) |
| Encryption | AES-256-GCM (encrypt) |
| Secure Storage | flutter_secure_storage |
| QR Scanning | mobile_scanner |
| Biometric Auth | local_auth |
| Animations | Lottie |
| Password Hashing | bcrypt |

---

## 🔒 Security

### Encryption Details

- **Algorithm**: AES-256-GCM (Galois/Counter Mode)
- **Key Derivation**: PBKDF2 with 10,000 iterations
- **Password Hashing**: bcrypt with salt
- **Secure Storage**: Platform keychain (iOS Keychain, Android KeyStore)

### Security Best Practices

1. **Data Encryption**: All sensitive data (secrets, account info) is encrypted at rest
2. **Key Management**: Encryption keys stored in platform secure storage
3. **No Cloud Storage**: Data never leaves the device
4. **Biometric Protection**: Optional biometric authentication layer
5. **Memory Safety**: Sensitive data cleared from memory after use
6. **Code Obfuscation**: Production builds use code obfuscation

### Security Audit

This is a proof-of-concept project. For production use, consider:
- Independent security audit
- Penetration testing
- Code signing and certificate pinning
- Additional key rotation mechanisms

---

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run tests with coverage:
```bash
flutter test --coverage
```

View coverage report:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 📖 Usage Guide

### Adding an Account

1. **Via QR Code**:
   - Tap the '+' button on the home screen
   - Select "Scan QR Code"
   - Point camera at the QR code
   - Account is automatically added

2. **Manually**:
   - Tap the '+' button
   - Select "Enter Manually"
   - Fill in account details (issuer, account name, secret)
   - Configure TOTP parameters (optional)
   - Save the account

### Managing Accounts

- **Copy Code**: Tap the code to copy it to clipboard
- **Edit Account**: Long press on account card
- **Delete Account**: Swipe left or use edit menu
- **Search**: Use the search bar at the top

### Settings

- **Theme**: Switch between light and dark modes
- **Biometric Lock**: Enable fingerprint/face ID
- **Export/Import**: Backup and restore accounts (encrypted)

---

## 🎨 Customization

### Changing Theme Colors

Edit `lib/app/theme.dart`:

```dart
static const Color primaryColor = Color(0xFF8B5CF6);    // Purple
static const Color secondaryColor = Color(0xFFEC4899);  // Pink
```

### Custom Splash Screen

Replace `assets/images/AuthenticatorLaunch.json` with your Lottie animation.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use `flutter format` before committing
- Add tests for new features
- Update documentation as needed

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design for UI/UX guidelines
- Open source community for packages and tools
- RFC 6238 specification for TOTP standard

---

## 📞 Contact & Support

- **GitHub**: [@premprashantjha](https://github.com/premprashantjha)
- **Repository**: [Authenticator](https://github.com/premprashantjha/Authenticator)
- **Issues**: [Report a bug](https://github.com/premprashantjha/Authenticator/issues)

---

<div align="center">

**⭐ Star this repository if you find it helpful!**

Made with ❤️ and Flutter

</div>
