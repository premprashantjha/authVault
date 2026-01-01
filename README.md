# Authenticator 🔐

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android-green.svg)

A secure, privacy-first TOTP authenticator app with encrypted backups and modern UI. Built with Flutter for Android.

## ✨ Features

### 🔒 Security First
- **Device Lock Protection** - Uses your device's built-in security (PIN/pattern/biometric)
- **Encrypted Local Storage** - All secrets encrypted at rest with strong encryption
- **Encrypted Backups** - Password-protected backups with industry-standard encryption
- **Hardware-Backed Keys** - Leverages Android Keystore when available
- **Clipboard Auto-Clear** - OTP codes cleared after 30 seconds
- **No Cloud Sync** - Your data never leaves your device
- **Screenshot Prevention** - Blocks screenshots and screen recording

### 💾 Encrypted Backup & Restore
- **Create Encrypted Backups** - Password-protected with strong encryption
- **Flexible Restore Options** - Skip duplicates, replace existing, or keep both
- **Password Strength Validation** - Ensures secure backup passwords
- **Local Storage** - Backups saved on device, share manually if needed
- **Retry Protection** - Up to 5 password attempts with clear feedback

### 🎨 Modern UX
- **Swipe Gestures** - Right to favorite, left to delete
- **Smooth Animations** - Professional, polished transitions
- **Pull-to-Refresh** - Update accounts with a simple gesture
- **Search & Filter** - Find accounts quickly
- **Auto Dark/Light Theme** - Follows system theme
- **Brand Logos** - Real brand icons for popular services (Google, GitHub, etc.)

### 🚀 Core Features
- **QR Code Scanning** - Quick account setup with camera
- **Manual Entry** - Add accounts without QR codes
- **TOTP Standard** - Compatible with all 2FA services (Google, GitHub, Microsoft, etc.)
- **Favorites System** - Mark important accounts
- **Offline First** - No internet required
- **Privacy Focused** - No analytics, no tracking, no data collection

## 📱 Screenshots

[Add screenshots here]

## 🔧 Installation

### Prerequisites
- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Android Studio or VS Code

### Setup

```bash
# Clone repository
git clone https://github.com/yourusername/authenticator.git
cd authenticator

# Install dependencies
flutter pub get

# Run app
flutter run
```

### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

## 🏗️ Architecture

### MVVM Pattern with Clean Architecture

```
lib/
├── main.dart                           # App entry point
├── app/                                # App configuration
│   ├── app.dart                        # Main app widget
│   └── theme.dart                      # Theme definitions
├── models/                             # Data models
│   └── account.dart                    # Account entity
├── view/                               # UI screens (View)
│   ├── home_screen.dart                # Main accounts list
│   ├── auth_wrapper.dart               # Device authentication
│   ├── backup_screen.dart              # Backup management
│   ├── settings_screen.dart            # App settings
│   ├── privacy_policy_screen.dart      # Privacy policy
│   ├── qr_scan_screen.dart             # QR code scanner
│   ├── onboarding_screen.dart          # Security guide
│   └── splash_screen.dart              # App splash
├── view_models/                        # State management (ViewModel)
│   └── account_view_model.dart         # Account state & logic
├── widgets/                            # Reusable components
│   ├── otp_card.dart                   # OTP display card
│   ├── animated_account_list.dart      # Animated list
│   ├── backup_password_dialog.dart     # Password input
│   ├── custom_snackbar.dart            # Notifications
│   └── empty_state_widget.dart         # Empty state
└── services/                           # Business logic
    ├── account_service.dart            # Account CRUD
    ├── totp_service.dart               # TOTP generation
    ├── encryption_service.dart         # Data encryption
    ├── backup_service.dart             # Backup/restore
    ├── backup_encryption_service.dart  # Backup encryption
    ├── database_service.dart           # SQLite operations
    ├── secure_storage_service.dart     # Secure key storage
    ├── keystore_service.dart           # Android Keystore
    ├── integrity_service.dart          # Database integrity
    ├── icon_service.dart               # Brand icons
    └── qr_scanner_service.dart         # QR parsing
```

### Tech Stack
- **Framework**: Flutter 3.8.1+
- **State Management**: Provider (MVVM)
- **Database**: SQLite with encryption
- **Security**: 
  - Encryption: XChaCha20-Poly1305 AEAD
  - Key Storage: flutter_secure_storage + Android Keystore
  - Backup: Argon2id + XChaCha20-Poly1305
- **UI**: Material Design 3
- **Icons**: Font Awesome (brand logos)

## 🔐 Security

### Encryption Architecture

**Data Encryption Key (DEK):**
- Generated once per app installation using CSPRNG
- 256-bit random key
- Stored in device secure storage (hardware-backed when available)
- Never stored in plaintext

**Secret Encryption:**
- Algorithm: XChaCha20-Poly1305 (AEAD)
- Random nonce per encryption
- Authenticated encryption with associated data (AAD)
- Secrets bound to account metadata

**Backup Encryption:**
- Key Derivation: Argon2id (OWASP recommended)
  - Memory: 64 MB
  - Iterations: 3
  - Parallelism: 4
- Cipher: XChaCha20-Poly1305
- Integrity: HMAC-SHA256
- Salt: 32 bytes random per backup

**Storage Security:**
- Android Keystore integration (hardware-backed)
- Hybrid storage strategy (direct + wrapped)
- Database integrity verification
- No plaintext secrets on disk

### Security Features
- ✅ Device lock authentication (PIN/pattern/biometric)
- ✅ Encrypted database
- ✅ Secure clipboard (auto-clear)
- ✅ No cloud backup
- ✅ No internet permissions
- ✅ Screenshot prevention
- ✅ Privacy overlay when app is in background
- ✅ Automatic re-lock on app switch

### Security Documentation

See [SECURITY_ARCHITECTURE.md](SECURITY_ARCHITECTURE.md) for complete technical details on:
- DEK generation and storage
- Encryption flow
- Threat model
- Security best practices

## 📖 Usage

### Adding Accounts

**Via QR Code:**
1. Tap the '+' button
2. Select "Scan QR Code"
3. Grant camera permission
4. Point camera at QR code
5. Account added automatically

**Manual Entry:**
1. Tap the '+' button
2. Select "Enter Manually"
3. Fill in:
   - Issuer (e.g., "Google")
   - Account Name (e.g., "user@gmail.com")
   - Secret Key (Base32 format)
4. Tap "Add Account"

### Managing Accounts

**Copy OTP Code:**
- Tap on the OTP code
- Code copied to clipboard
- Auto-clears after 30 seconds

**Add to Favorites:**
- Tap star icon, OR
- Swipe right on account card

**Delete Account:**
- Tap delete icon, OR
- Swipe left on account card
- Confirm deletion

**Search:**
- Tap search icon
- Search by issuer or account name

### Backup & Restore

**Create Backup:**
1. Settings → Backup & Restore
2. Tap "Create Backup"
3. Enter strong password (6+ characters)
4. Confirm password
5. Backup saved as `.cdac` file
6. Optional: Share backup file

**Restore Backup:**
1. Settings → Backup & Restore
2. Tap "Import Backup"
3. Select `.cdac` backup file
4. Choose merge strategy:
   - Skip Duplicates
   - Replace Existing
   - Keep Both
5. Enter backup password
6. Accounts restored

**Password Retry:**
- Up to 5 attempts allowed
- Clear error messages
- Backup remains secure

## 🎨 Customization

### Theme
- Automatic light/dark mode
- Follows system theme
- CDAC branding colors

### Device Authentication
- Uses device's built-in security
- Supports PIN, pattern, fingerprint, face unlock
- Automatic re-lock when app goes to background

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/services/totp_service_test.dart
```

## 📦 Dependencies

### Core
- `provider: ^6.1.5` - State management
- `sqflite: ^2.4.2` - Local database
- `flutter_secure_storage: ^9.2.4` - Secure key storage
- `cryptography: ^2.9.0` - Encryption
- `local_auth: ^2.3.0` - Biometric authentication

### Backup & Security
- `bcrypt: ^1.1.3` - Password hashing
- `crypto: ^3.0.6` - Hash functions
- `encrypt: ^5.0.3` - Additional encryption utilities

### UI & Utilities
- `mobile_scanner: ^7.1.3` - QR code scanning
- `font_awesome_flutter: ^10.7.0` - Brand icons
- `share_plus: ^10.1.2` - File sharing
- `file_picker: ^8.1.4` - File selection
- `path_provider: ^2.1.5` - File paths
- `shared_preferences: ^2.2.2` - Settings storage

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) style
4. Add tests for new features
5. Run `flutter format` before committing
6. Submit Pull Request

## 🔒 Privacy

This app is **privacy-first**:
- ✅ No data collection
- ✅ No analytics or tracking
- ✅ No third-party services
- ✅ No internet required
- ✅ All data stored locally and encrypted
- ✅ Transparent security architecture

See [Privacy Policy](lib/view/privacy_policy_screen.dart) for full details.

## 🐛 Security Disclosure

Found a security vulnerability? Please email **support@cdac.in** instead of opening a public issue.

**Response Time**: 48 hours

## 📞 Contact

- **Organization**: Centre for Development of Advanced Computing (C-DAC)
- **Package**: com.cdac.authenticator
- **Support**: support@cdac.in

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev/) - UI framework
- [Provider](https://pub.dev/packages/provider) - State management
- [SQLite](https://pub.dev/packages/sqflite) - Local database
- [Cryptography](https://pub.dev/packages/cryptography) - Encryption
- [Mobile Scanner](https://pub.dev/packages/mobile_scanner) - QR scanning
- [Font Awesome](https://pub.dev/packages/font_awesome_flutter) - Brand icons

## 📊 Project Status

**Version**: 1.0.0  
**Status**: ✅ Production Ready  
**Platform**: Android 8.0+  
**Last Updated**: December 2024

---

Made with ❤️ by C-DAC using Flutter
