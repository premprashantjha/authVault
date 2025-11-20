# Keystore & Secrets Sharing Guide

## 🔐 Security First Approach

The release keystore and passwords are **NEVER** committed to Git for security reasons.

## 📋 What You Need to Share

1. **Keystore File**: `android/app/release.keystore`
2. **4 Credentials**:
   - Keystore password
   - Key alias: `release`
   - Key password
   - Keystore file path: `android/app/release.keystore`

## 🎯 Recommended Sharing Methods

### **Option 1: Password Manager (BEST)**
Use a team password manager like:
- **1Password** (Teams feature)
- **Bitwarden** (Organizations)
- **LastPass** (Teams)
- **Keeper** (Business)

**Steps:**
1. Upload `release.keystore` as a secure file attachment
2. Store all 4 credentials as a secure note
3. Share access with team members

---

### **Option 2: Encrypted Cloud Storage**

**Steps:**
1. Encrypt the keystore:
   ```powershell
   # Install GPG if not already installed
   # Download from: https://gnupg.org/download/
   
   gpg -c android/app/release.keystore
   # Creates: release.keystore.gpg
   ```

2. Upload encrypted file to:
   - Google Drive (with restricted access)
   - OneDrive (with password protection)
   - Dropbox (with link expiration)

3. Share decryption password separately via:
   - Encrypted messaging (Signal, WhatsApp)
   - Password manager
   - In-person

4. Team member decrypts:
   ```powershell
   gpg -d release.keystore.gpg > android/app/release.keystore
   ```

---

### **Option 3: CI/CD Secrets (For Automated Builds)**

#### **GitHub Actions:**
1. Go to: Repository → Settings → Secrets and variables → Actions
2. Add secrets:
   - `AUTHENTICATOR_KEYSTORE_PASSWORD`
   - `AUTHENTICATOR_KEY_PASSWORD`
3. Base64 encode keystore:
   ```powershell
   $bytes = [System.IO.File]::ReadAllBytes("android/app/release.keystore")
   [Convert]::ToBase64String($bytes) | Out-File keystore_base64.txt
   ```
4. Add `AUTHENTICATOR_KEYSTORE_BASE64` secret with the content

#### **GitLab CI:**
Settings → CI/CD → Variables → Add variable

---

## 🖥️ Setting Up on a New System

### **Step 1: Get the Keystore**
Obtain `release.keystore` from:
- Password manager
- Encrypted cloud storage
- Team lead

Place it at: `android/app/release.keystore`

### **Step 2: Set Environment Variables**

#### **Temporary (Current Session Only):**
```powershell
$env:AUTHENTICATOR_KEYSTORE_FILE="android/app/release.keystore"
$env:AUTHENTICATOR_KEYSTORE_PASSWORD="<your_keystore_password>"
$env:AUTHENTICATOR_KEY_ALIAS="release"
$env:AUTHENTICATOR_KEY_PASSWORD="<your_key_password>"
```

#### **Permanent (Survives Restarts):**
```powershell
[System.Environment]::SetEnvironmentVariable('AUTHENTICATOR_KEYSTORE_FILE', 'android/app/release.keystore', 'User')
[System.Environment]::SetEnvironmentVariable('AUTHENTICATOR_KEYSTORE_PASSWORD', 'your_password', 'User')
[System.Environment]::SetEnvironmentVariable('AUTHENTICATOR_KEY_ALIAS', 'release', 'User')
[System.Environment]::SetEnvironmentVariable('AUTHENTICATOR_KEY_PASSWORD', 'your_password', 'User')
```

**Restart PowerShell** after setting permanent variables.

### **Step 3: Verify Setup**
```powershell
# Check all variables are set
Write-Host "AUTHENTICATOR_KEYSTORE_FILE: $env:AUTHENTICATOR_KEYSTORE_FILE"
Write-Host "AUTHENTICATOR_KEY_ALIAS: $env:AUTHENTICATOR_KEY_ALIAS"
Write-Host "Passwords: $(if($env:AUTHENTICATOR_KEYSTORE_PASSWORD -and $env:AUTHENTICATOR_KEY_PASSWORD){'✓ Set'}else{'✗ Missing'})"
```

### **Step 4: Build Release APK**
```powershell
flutter build apk --release
```

---

## 📝 Creating Local Properties File (Alternative)

Instead of environment variables, you can create a local properties file:

**Create**: `android/keystore.properties` (NOT committed to Git)
```properties
storeFile=release.keystore
storePassword=your_keystore_password
keyAlias=release
keyPassword=your_key_password
```

**Update** `android/app/build.gradle.kts`:
```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("keystore.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            storeFile = file(keystoreProperties["storeFile"] ?: "release.keystore")
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }
}
```

---

## ⚠️ Security Checklist

- [ ] Keystore file is in `.gitignore`
- [ ] Never commit passwords to Git
- [ ] Store keystore backup in secure location
- [ ] Use different passwords for keystore and key
- [ ] Restrict team access to need-to-know basis
- [ ] Change passwords if compromised
- [ ] Document who has access
- [ ] Keep encrypted backup in case of emergency

---

## 🆘 Emergency: Lost Keystore

**If you lose the keystore, you CANNOT update the app on Play Store!**

You'll need to:
1. Create a new keystore
2. Publish as a completely new app with new package name
3. Existing users cannot update, must reinstall

**Prevention:**
- Keep encrypted backups in 3 locations
- Document in password manager
- Share with trusted team lead

---

## 📧 Sharing Credentials Summary

| Method | Security | Ease | Best For |
|--------|----------|------|----------|
| Password Manager | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Teams |
| Encrypted Cloud | ⭐⭐⭐⭐ | ⭐⭐⭐ | Small teams |
| CI/CD Secrets | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | Automation |
| Local Properties | ⭐⭐⭐ | ⭐⭐⭐⭐ | Solo dev |
| Email/Slack | ⭐ | ⭐⭐⭐⭐⭐ | ❌ NEVER |

---

## 🔑 Current Keystore Details

- **Location**: `android/app/release.keystore`
- **Alias**: `release`
- **Algorithm**: RSA 2048-bit
- **Valid Until**: April 7, 2053
- **Certificate SHA256**: A5:B5:5E:8C:35:21:44:FC:CF:99:0E:26:49:FF:54:B8:BD:5D:E8:0A:99:3E:FB:96:C1:AA:91:8E:0F:B8:58:96

---

**Remember**: The keystore is the key to your app's identity. Treat it like your bank password! 🔐
