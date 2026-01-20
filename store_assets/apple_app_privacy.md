# Apple App Privacy Details

**App:** Authenticator  
**Bundle ID:** com.cdac.authenticator  
**Version:** 1.0.0  
**Date Prepared:** January 19, 2025

---

## Instructions

Use this document to complete the App Privacy questionnaire in App Store Connect. This creates the "Privacy Nutrition Label" that users see on the App Store.

**Form Location:** App Store Connect → App Information → App Privacy

---

## Section 1: Privacy Practices

### Question: Does this app collect data from this app?

**Answer:** NO

**Explanation:**
The app does NOT collect any data from users. All authentication data is stored locally on the user's device in encrypted form. The app functions completely offline and does not transmit any data to servers.

---

## Section 2: Data Types (All Answers: NO)

Since we answered NO to data collection, you must confirm that NONE of the following data types are collected. Apple will ask about each category:

### Contact Info
- [ ] Name
- [ ] Email Address
- [ ] Phone Number
- [ ] Physical Address
- [ ] Other User Contact Info

**Answer:** NO - We do not collect any contact information.

---

### Health & Fitness
- [ ] Health
- [ ] Fitness

**Answer:** NO - We do not collect any health or fitness data.

---

### Financial Info
- [ ] Payment Info
- [ ] Credit Info
- [ ] Other Financial Info

**Answer:** NO - We do not collect any financial information.

---

### Location
- [ ] Precise Location
- [ ] Coarse Location

**Answer:** NO - We do not collect any location data.

---

### Sensitive Info
- [ ] Sensitive Info

**Answer:** NO - We do not collect any sensitive information.

---

### Contacts
- [ ] Contacts

**Answer:** NO - We do not access the user's contacts.

---

### User Content
- [ ] Emails or Text Messages
- [ ] Photos or Videos
- [ ] Audio Data
- [ ] Gameplay Content
- [ ] Customer Support
- [ ] Other User Content

**Answer:** NO - We do not collect any user content. Camera is used only for QR code scanning, and images are processed in memory without storage.

---

### Browsing History
- [ ] Browsing History

**Answer:** NO - We do not collect browsing history.

---

### Search History
- [ ] Search History

**Answer:** NO - We do not collect search history. In-app search is performed locally and not recorded.

---

### Identifiers
- [ ] User ID
- [ ] Device ID

**Answer:** NO - We do not collect any identifiers.

---

### Purchases
- [ ] Purchase History

**Answer:** NO - The app is free with no in-app purchases.

---

### Usage Data
- [ ] Product Interaction
- [ ] Advertising Data
- [ ] Other Usage Data

**Answer:** NO - We do not collect any usage data, analytics, or telemetry.

---

### Diagnostics
- [ ] Crash Data
- [ ] Performance Data
- [ ] Other Diagnostic Data

**Answer:** NO - We do not collect crash logs or diagnostic data.

---

### Other Data
- [ ] Other Data Types

**Answer:** NO - We do not collect any other data types.

---

## Section 3: Tracking

### Question: Do you or your third-party partners use data from this app for tracking purposes?

**Answer:** NO

**Explanation:**
We do not track users across apps or websites owned by other companies. We do not use any tracking technologies, advertising networks, or analytics services.

**Definition of Tracking (per Apple):**
Tracking refers to linking data collected from your app with data collected from other companies' apps, websites, or offline properties for targeted advertising or advertising measurement purposes, or sharing data with data brokers.

**Our Practice:**
- No advertising networks
- No analytics services
- No data brokers
- No cross-app tracking
- No user profiling

---

## Section 4: Third-Party SDKs

### Question: List all third-party SDKs used in your app

**Answer:** The following open-source packages are used, but NONE collect or transmit user data:

#### Core Functionality Packages
1. **sqflite** (v2.4.2)
   - Purpose: Local SQLite database
   - Data Collection: None
   - Network Access: None

2. **flutter_secure_storage** (v9.2.4)
   - Purpose: Secure key storage using iOS Keychain
   - Data Collection: None
   - Network Access: None

3. **cryptography** (v2.9.0)
   - Purpose: Encryption library (XChaCha20-Poly1305)
   - Data Collection: None
   - Network Access: None

4. **encrypt** (v5.0.3)
   - Purpose: Encryption utilities
   - Data Collection: None
   - Network Access: None

5. **crypto** (v3.0.6)
   - Purpose: Cryptographic functions
   - Data Collection: None
   - Network Access: None

#### State Management
6. **provider** (v6.1.5+1)
   - Purpose: State management
   - Data Collection: None
   - Network Access: None

#### Device Features
7. **mobile_scanner** (v7.1.3)
   - Purpose: QR code scanning using device camera
   - Data Collection: None (images processed in memory only)
   - Network Access: None

8. **local_auth** (v2.3.0)
   - Purpose: Biometric authentication (Face ID, Touch ID)
   - Data Collection: None (uses iOS biometric APIs)
   - Network Access: None

9. **permission_handler** (v12.0.1)
   - Purpose: Permission management
   - Data Collection: None
   - Network Access: None

10. **safe_device** (v1.3.8)
    - Purpose: Jailbreak detection
    - Data Collection: None
    - Network Access: None

#### File Operations
11. **file_picker** (v8.1.4)
    - Purpose: File selection for backup import
    - Data Collection: None
    - Network Access: None

12. **share_plus** (v10.1.2)
    - Purpose: File sharing (user-initiated)
    - Data Collection: None
    - Network Access: None

13. **path_provider** (v2.1.5)
    - Purpose: File system paths
    - Data Collection: None
    - Network Access: None

#### UI Components
14. **qr_flutter** (v4.1.0)
    - Purpose: QR code generation for export
    - Data Collection: None
    - Network Access: None

15. **font_awesome_flutter** (v10.7.0)
    - Purpose: Icon library
    - Data Collection: None
    - Network Access: None

16. **flutter_markdown** (v0.7.4+1)
    - Purpose: Markdown rendering for legal documents
    - Data Collection: None
    - Network Access: None

#### Utilities
17. **base32** (v2.2.0)
    - Purpose: Base32 encoding for TOTP secrets
    - Data Collection: None
    - Network Access: None

18. **bcrypt** (v1.1.3)
    - Purpose: Password hashing for backups
    - Data Collection: None
    - Network Access: None

19. **shared_preferences** (v2.2.2)
    - Purpose: Local app preferences
    - Data Collection: None
    - Network Access: None

20. **path** (v1.9.1)
    - Purpose: File path manipulation
    - Data Collection: None
    - Network Access: None

**Important Note:** All packages are open-source and can be verified on pub.dev. None of these packages collect, transmit, or share user data.

---

## Section 5: Data Use

Since we don't collect data, this section is not applicable. However, for clarity:

### Data Stored Locally (Not Collected)
The following data is stored ONLY on the user's device:
- TOTP secrets (encrypted)
- Account names and issuers
- App preferences (theme, security settings)
- Encrypted backup files (user-created)

### Data Use Purpose
- **Functionality:** All data is used solely to provide TOTP authentication
- **No Analytics:** No usage tracking or analytics
- **No Advertising:** No advertising or marketing
- **No Third-Party Sharing:** Data never leaves the device

---

## Section 6: Data Linked to User

### Question: Is any data linked to the user's identity?

**Answer:** NO

**Explanation:**
We do not collect any data, so there is no data to link to user identity. All data stored locally is not associated with any user account or identifier.

---

## Section 7: Data Used to Track User

### Question: Is any data used to track the user?

**Answer:** NO

**Explanation:**
We do not track users. No data is collected for tracking purposes, and we do not use any tracking technologies.

---

## Section 8: Encryption

### Question: Describe your app's encryption practices

**Answer:**

**Data Encryption at Rest:**
- Algorithm: XChaCha20-Poly1305 AEAD (Authenticated Encryption with Associated Data)
- Key Storage: iOS Keychain (hardware-backed when available)
- Key Size: 256-bit encryption keys
- Implementation: Uses Apple's Security framework via flutter_secure_storage

**Backup Encryption:**
- Key Derivation: Argon2id (memory-hard function)
- Cipher: XChaCha20-Poly1305
- Integrity: HMAC-SHA256
- Salt: 32 bytes random per backup

**No Data in Transit:**
- App functions completely offline
- No network transmission of user data
- No cloud synchronization

---

## Section 9: Privacy Policy

### Privacy Policy URL
**Required:** YES  
**URL:** [Your hosted privacy policy URL or link to in-app policy]

**Note:** Apple requires a publicly accessible privacy policy URL. You can:
1. Host the privacy policy on a website
2. Create a GitHub Pages site with the policy
3. Use a privacy policy hosting service

---

## Section 10: Contact Information

### Privacy Contact Email
**Email:** support@cdac.in

### Organization
**Name:** Centre for Development of Advanced Computing (C-DAC)

---

## Summary for Quick Reference

| Category | Collected? | Tracked? | Linked to User? |
|----------|-----------|----------|-----------------|
| Contact Info | NO | NO | NO |
| Health & Fitness | NO | NO | NO |
| Financial Info | NO | NO | NO |
| Location | NO | NO | NO |
| Sensitive Info | NO | NO | NO |
| Contacts | NO | NO | NO |
| User Content | NO | NO | NO |
| Browsing History | NO | NO | NO |
| Search History | NO | NO | NO |
| Identifiers | NO | NO | NO |
| Purchases | NO | NO | NO |
| Usage Data | NO | NO | NO |
| Diagnostics | NO | NO | NO |
| Other Data | NO | NO | NO |

**Tracking:** NO  
**Third-Party SDKs:** 20 packages (none collect data)  
**Encryption:** YES (XChaCha20-Poly1305)

---

## App Store Privacy Label Preview

When users view your app on the App Store, they will see:

**Data Not Collected**
The developer does not collect any data from this app.

**Privacy Practices**
- No data collection
- No tracking
- Strong encryption
- Offline functionality

---

## Supporting Documentation

If Apple requests additional information during review:

1. **No Network Activity:** App functions completely offline
2. **Local Storage Only:** All data in encrypted SQLite database
3. **No Analytics:** No Firebase, Google Analytics, or similar services
4. **No Advertising:** No ad networks or tracking pixels
5. **Open Source Packages:** All dependencies are open-source and verifiable
6. **Encryption Details:** XChaCha20-Poly1305 with hardware-backed keys

---

## Notes for Submission

1. **Accuracy is Critical:** Apple verifies privacy claims through app analysis
2. **Update When Needed:** If you add features that collect data, update immediately
3. **Be Specific:** Provide detailed explanations when requested
4. **Review Period:** Privacy label review typically takes 1-2 days
5. **Consistency:** Ensure answers match your Privacy Policy exactly

---

## Common Apple Review Questions

**Q: Why do you request camera permission?**
A: Camera is used only for QR code scanning when adding accounts. Images are processed in memory and never stored or transmitted.

**Q: Why do you request biometric permission?**
A: Biometric authentication (Face ID/Touch ID) is used to protect app access. No biometric data is collected or stored by the app.

**Q: Why is INTERNET permission declared?**
A: Some Flutter packages require this permission to be declared, but the app does not transmit any data over the network. All functionality is offline.

**Q: How do users delete their data?**
A: Users can delete individual accounts within the app or uninstall the app to permanently remove all data.

---

**Prepared By:** Development Team  
**Review Date:** January 19, 2025  
**Next Review:** Before each app update  
**Apple Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/#privacy

