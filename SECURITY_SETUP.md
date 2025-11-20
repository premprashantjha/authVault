# AuthVault Security Setup Guide

## ⚠️ CRITICAL: Release Signing Configuration

The app is configured to use a **release keystore** for signing production builds. You MUST set this up before building release APKs.

### Quick Setup

1. **Generate a release keystore** (one-time):
   ```powershell
   cd android\app
   keytool -genkey -v -keystore release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias release
   ```

2. **Set environment variables** (for each build session):
   ```powershell
   # PowerShell
   $env:AUTHVAULT_KEYSTORE_FILE="android/app/release.keystore"
   $env:AUTHVAULT_KEYSTORE_PASSWORD="your_keystore_password"
   $env:AUTHVAULT_KEY_ALIAS="release"
   $env:AUTHVAULT_KEY_PASSWORD="your_key_password"
   ```

   Or for permanent setup, add to your PowerShell profile:
   ```powershell
   notepad $PROFILE
   # Add the $env: lines above
   ```

3. **Build release APK**:
   ```powershell
   flutter build apk --release
   ```

### Security Best Practices

#### ✅ DO:
- Store keystore file in a secure location (NOT in git repository)
- Use strong, unique passwords (20+ characters)
- Backup your keystore file securely
- Use environment variables for CI/CD pipelines
- Rotate keys every 2-3 years

#### ❌ DON'T:
- Commit `release.keystore` to version control
- Share keystore passwords in plain text
- Use the same password for multiple keystores
- Lose your keystore (you can't update your app without it!)

### For CI/CD (GitHub Actions, etc.)

Set secrets in your repository settings:
- `AUTHVAULT_KEYSTORE_FILE` - Base64 encoded keystore
- `AUTHVAULT_KEYSTORE_PASSWORD` - Keystore password
- `AUTHVAULT_KEY_ALIAS` - Key alias
- `AUTHVAULT_KEY_PASSWORD` - Key password

Example GitHub Actions workflow:
```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.AUTHVAULT_KEYSTORE_FILE }}" | base64 --decode > android/app/release.keystore

- name: Build release APK
  env:
    AUTHVAULT_KEYSTORE_FILE: android/app/release.keystore
    AUTHVAULT_KEYSTORE_PASSWORD: ${{ secrets.AUTHVAULT_KEYSTORE_PASSWORD }}
    AUTHVAULT_KEY_ALIAS: ${{ secrets.AUTHVAULT_KEY_ALIAS }}
    AUTHVAULT_KEY_PASSWORD: ${{ secrets.AUTHVAULT_KEY_PASSWORD }}
  run: flutter build apk --release
```

---

## 📋 Security Checklist

Before releasing to production, ensure:

- [ ] Release keystore is generated and secured
- [ ] Environment variables are set
- [ ] Debug logging is disabled (ProGuard will remove it)
- [ ] Root/jailbreak detection is enabled
- [ ] Screenshot prevention is active
- [ ] Network security config is in place
- [ ] Android backup is disabled
- [ ] ProGuard obfuscation is enabled
- [ ] PIN complexity requirements are enforced
- [ ] Clipboard auto-clear is set to 30 seconds

---

## 🔒 Additional Security Features

### Root/Jailbreak Detection
The app checks for device security on startup and warns users if:
- Device is rooted/jailbroken
- Running on an emulator (production only)
- Developer mode is enabled
- App is installed on external storage

### Screenshot Prevention (Android)
FLAG_SECURE is enabled to prevent:
- Screenshots
- Screen recordings
- Recent apps preview

**Note:** This feature only works on Android. iOS has system-level restrictions.

### PIN Complexity Requirements
Strong PINs are enforced with validation for:
- Minimum 6 digits
- No sequential numbers (123456, 654321)
- No repeated digits (111111, 121212)
- No common PINs (from breach databases)
- No patterns (112233, 123123)

### Data Protection
- **Encryption:** AES-256-GCM for all secrets
- **Hashing:** Bcrypt for PIN storage
- **Secure Storage:** Hardware-backed Android Keystore
- **Memory Protection:** Sensitive data purged on app lock
- **No Backups:** Android backups explicitly disabled

---

## 🚨 Security Incident Response

If you discover a security vulnerability:

1. **DO NOT** open a public GitHub issue
2. Email: security@authvault.app (or your security contact)
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (optional)

Expected response time: 48 hours

---

## 📝 Security Audit Results

Last audit: November 20, 2025  
Rating: **8.5/10** (after P0 fixes)

See `SECURITY_AUDIT.md` for full details.

---

## 🔧 Troubleshooting

### "Signing config not found" error
- Ensure environment variables are set in your current shell session
- Verify keystore file path is correct (relative to android/app/)

### "Wrong password" error
- Double-check AUTHVAULT_KEYSTORE_PASSWORD and AUTHVAULT_KEY_PASSWORD
- Ensure no extra spaces or quotes in environment variables

### ProGuard build fails
- Check `android/app/proguard-rules.pro` for syntax errors
- Ensure all Flutter plugin dependencies are compatible with R8

---

## 📦 Release Build Command

Complete release build process:

```powershell
# 1. Clean previous builds
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Set environment variables (if not permanent)
$env:AUTHVAULT_KEYSTORE_FILE="android/app/release.keystore"
$env:AUTHVAULT_KEYSTORE_PASSWORD="your_password"
$env:AUTHVAULT_KEY_ALIAS="release"
$env:AUTHVAULT_KEY_PASSWORD="your_password"

# 4. Build release APK
flutter build apk --release

# 5. Build App Bundle (for Google Play)
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

---

## 🔐 Keystore Backup Recommendations

1. **Encrypted backup:**
   ```powershell
   # Encrypt keystore with GPG
   gpg -c release.keystore
   # Generates: release.keystore.gpg
   ```

2. **Store in multiple secure locations:**
   - Password manager (1Password, LastPass)
   - Encrypted cloud storage (not public git!)
   - Hardware security key
   - Physical secure storage

3. **Document keystore details** (store separately):
   - Keystore password
   - Key alias
   - Key password
   - Creation date
   - Validity period

**Remember:** If you lose your keystore, you cannot update your app on Google Play. You'd have to publish as a new app.

---

## 📄 License & Legal

AuthVault - TOTP Authenticator  
© 2025 All rights reserved

This security setup guide is part of the AuthVault project documentation.
