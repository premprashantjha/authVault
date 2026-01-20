# Authenticator

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1+-02569B?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Android-green.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

A secure, privacy-first TOTP authenticator with encrypted backups. Built with Flutter for Android.

## Features

- **Device Lock Authentication** - PIN/pattern/biometric protection
- **Encrypted Storage** - XChaCha20-Poly1305 AEAD encryption
- **Manual Backups** - Password-protected encrypted backups
- **QR Import/Export** - Device-to-device transfers
- **Bulk Operations** - Multi-select for delete and share
- **Swipe Gestures** - Quick favorite/delete actions
- **Search & Filter** - Find accounts by issuer or name
- **Offline First** - No internet required, no cloud sync
- **Privacy Focused** - No analytics, no tracking, no data collection

## Getting Started

### Prerequisites
- Flutter SDK 3.8.1+
- Android SDK (API 26+)

### Installation

```bash
git clone https://github.com/yourusername/authenticator.git
cd authenticator
flutter pub get
flutter run
```

### Build

```bash
# Debug APK
flutter build apk

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

## Architecture

### MVVM Pattern

```
lib/
├── app/                    # Configuration & theme
├── models/                 # Data models
├── view/                   # UI screens
├── view_models/            # State management
├── widgets/                # Reusable components
└── services/               # Business logic
    ├── account_service.dart
    ├── totp_service.dart
    ├── encryption_service.dart
    ├── backup_service.dart
    ├── database_service.dart
    └── ...
```

### Tech Stack
- **Framework**: Flutter 3.8.1+
- **State Management**: Provider (MVVM)
- **Database**: SQLite (encrypted)
- **Encryption**: XChaCha20-Poly1305 AEAD
- **Key Storage**: Android Keystore + flutter_secure_storage
- **Backup**: Argon2id + XChaCha20-Poly1305
- **UI**: Material Design 3

## Security

### Encryption

**Data Encryption:**
- Algorithm: XChaCha20-Poly1305 AEAD
- Key: 256-bit DEK (device-generated, hardware-backed)
- Storage: Android Keystore + flutter_secure_storage
- Nonce: Random per encryption

**Backup Encryption:**
- KDF: Argon2id (64MB, 3 iterations, 4 parallelism)
- Cipher: XChaCha20-Poly1305
- Integrity: HMAC-SHA256
- Salt: 32 bytes random

### Security Features
- Device lock authentication (PIN/pattern/biometric)
- Encrypted database (no plaintext secrets)
- Secure clipboard (auto-clear after 30s)
- Screenshot prevention
- Privacy overlay on app switch
- No internet permissions
- No cloud sync

### Threat Model
- ✅ Device theft (encrypted at rest)
- ✅ Malware (hardware-backed keys)
- ✅ Backup theft (password-protected)
- ✅ Screen capture (blocked)
- ⚠️ Rooted devices (reduced security)
- ⚠️ Physical access while unlocked (user responsibility)

## Usage

### Adding Accounts

**QR Code:**
1. Tap '+' → Scan QR Code
2. Grant camera permission
3. Scan QR code

**Manual Entry:**
1. Tap '+' → Enter Manually
2. Fill issuer, account name, secret key (Base32)
3. Tap "Add Account"

### Managing Accounts

- **Copy OTP**: Tap code (auto-clears after 30s)
- **Favorite**: Tap star or swipe right
- **Delete**: Tap delete icon or swipe left
- **Bulk Delete**: Long-press to enter selection mode
- **Search**: Tap search icon, filter by issuer/name

### Backup & Restore

**Manual Backup:**
1. Settings → Backup & Restore → Create Backup
2. Enter password (6+ characters)
3. Save `.cdac` file

**Restore:**
1. Settings → Backup & Restore → Import Backup
2. Select `.cdac` file
3. Choose merge strategy (Skip/Replace/Keep Both)
4. Enter password

**QR Transfer:**
1. Export: Settings → Export to QR Code
2. Import: Settings → Import from Other Apps → Scan QR

## Testing

```bash
flutter test                                    # Run all tests
flutter test --coverage                         # With coverage
flutter test test/services/totp_service_test.dart  # Specific test
```

## Dependencies

**Core:**
- `provider` - State management
- `sqflite` - Local database
- `flutter_secure_storage` - Secure key storage
- `cryptography` - Encryption
- `local_auth` - Biometric authentication

**UI & Utilities:**
- `mobile_scanner` - QR code scanning
- `font_awesome_flutter` - Brand icons
- `share_plus` - File sharing
- `file_picker` - File selection
- `path_provider` - File paths

See [pubspec.yaml](pubspec.yaml) for complete list.

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/name`)
3. Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
4. Add tests for new features
5. Run `flutter format` before committing
6. Submit Pull Request

## Privacy

- No data collection
- No analytics or tracking
- No third-party services
- No internet required
- All data stored locally and encrypted

See [Privacy Policy](lib/view/privacy_policy_screen.dart) for details.

## Security Disclosure

Found a security vulnerability? Email **support@cdac.in** instead of opening a public issue.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contact

**Organization**: Centre for Development of Advanced Computing (C-DAC)  
**Package**: `com.cdac.authenticator`  
**Support**: support@cdac.in

---

**Version**: 1.0.0 | **Platform**: Android 8.0+ | **Status**: Production Ready
