# Google Play Data Safety Declaration

**App:** Authenticator  
**Package:** com.cdac.authenticator  
**Version:** 1.0.0  
**Date Prepared:** January 19, 2025

---

## Instructions

Use this document to complete the Data Safety form in Google Play Console. Copy and paste the answers below into the appropriate fields.

**Form Location:** Google Play Console → App Content → Data Safety

---

## Section 1: Data Collection and Security

### Question: Does your app collect or share any of the required user data types?

**Answer:** NO

**Explanation:**
The app does NOT collect, transmit, or share any user data. All data is stored locally on the user's device in encrypted form. The app functions completely offline and does not require an internet connection.

---

## Section 2: Data Types (All Answers: NO)

Since we answered NO to data collection, you will need to confirm that NONE of the following data types are collected:

### Location
- [ ] Approximate location
- [ ] Precise location

**Answer:** NO - We do not collect any location data.

---

### Personal Info
- [ ] Name
- [ ] Email address
- [ ] User IDs
- [ ] Address
- [ ] Phone number
- [ ] Race and ethnicity
- [ ] Political or religious beliefs
- [ ] Sexual orientation
- [ ] Other personal info

**Answer:** NO - We do not collect any personal information.

---

### Financial Info
- [ ] User payment info
- [ ] Purchase history
- [ ] Credit score
- [ ] Other financial info

**Answer:** NO - We do not collect any financial information.

---

### Health and Fitness
- [ ] Health info
- [ ] Fitness info

**Answer:** NO - We do not collect any health or fitness data.

---

### Messages
- [ ] Emails
- [ ] SMS or MMS
- [ ] Other in-app messages

**Answer:** NO - We do not collect any messages.

---

### Photos and Videos
- [ ] Photos
- [ ] Videos

**Answer:** NO - Camera is used only for QR code scanning. Images are processed in memory and never stored or transmitted.

---

### Audio Files
- [ ] Voice or sound recordings
- [ ] Music files
- [ ] Other audio files

**Answer:** NO - We do not collect any audio files.

---

### Files and Docs
- [ ] Files and docs

**Answer:** NO - We do not collect files. Users can create encrypted backup files, but these are created and stored by the user, not collected by the app.

---

### Calendar
- [ ] Calendar events

**Answer:** NO - We do not access calendar data.

---

### Contacts
- [ ] Contacts

**Answer:** NO - We do not access contacts.

---

### App Activity
- [ ] App interactions
- [ ] In-app search history
- [ ] Installed apps
- [ ] Other user-generated content
- [ ] Other actions

**Answer:** NO - We do not collect any app activity or usage data.

---

### Web Browsing
- [ ] Web browsing history

**Answer:** NO - We do not access web browsing data.

---

### App Info and Performance
- [ ] Crash logs
- [ ] Diagnostics
- [ ] Other app performance data

**Answer:** NO - We do not collect crash logs or diagnostics data.

---

### Device or Other IDs
- [ ] Device or other IDs

**Answer:** NO - We do not collect device IDs or any identifiers.

---

## Section 3: Security Practices

### Question: Is all of the user data collected by your app encrypted in transit?

**Answer:** N/A (Not Applicable)

**Explanation:**
No data is transmitted over the network. The app functions completely offline. All data remains on the user's device.

---

### Question: Do you provide a way for users to request that their data is deleted?

**Answer:** YES

**Explanation:**
Users can delete their data in the following ways:
1. Delete individual accounts within the app
2. Clear all data by uninstalling the app
3. All data is stored locally, so uninstalling the app permanently removes all user data

**Data Deletion Method:** Uninstall the app to permanently delete all data.

---

### Question: Is all of the user data collected by your app encrypted at rest?

**Answer:** YES

**Explanation:**
All sensitive data is encrypted at rest using industry-standard encryption:
- **Algorithm:** XChaCha20-Poly1305 AEAD (Authenticated Encryption with Associated Data)
- **Key Storage:** Hardware-backed Android Keystore when available, with fallback to flutter_secure_storage
- **Key Size:** 256-bit encryption keys
- **Backup Encryption:** Argon2id key derivation with XChaCha20-Poly1305 encryption

No plaintext secrets are ever stored on the device.

---

### Question: Will your app's Play Family Policy requirements be the same for all users?

**Answer:** YES

**Explanation:**
The app does not target children specifically and has the same privacy practices for all users. No data is collected from any users, regardless of age.

---

### Question: Has your app undergone an independent security review?

**Answer:** NO (Optional)

**Explanation:**
While the app has not undergone a formal third-party security audit, it uses industry-standard encryption libraries and follows security best practices. The security implementation can be verified through code review.

---

## Section 4: Additional Information

### Privacy Policy URL
**Required:** YES  
**URL:** [Your privacy policy URL - will be the app's in-app privacy policy or hosted version]

### Data Safety Contact Email
**Email:** support@cdac.in

---

## Summary for Quick Reference

| Question | Answer | Details |
|----------|--------|---------|
| Collect or share data? | NO | All data stored locally only |
| All data types | NO | No data collection of any kind |
| Encrypted in transit? | N/A | No network transmission |
| Encrypted at rest? | YES | XChaCha20-Poly1305 AEAD |
| Data deletion? | YES | Uninstall app |
| Same for all users? | YES | No age-specific differences |
| Security review? | NO | Optional |

---

## Supporting Evidence (For Review)

If Google requests evidence of your data practices, you can reference:

1. **No Network Permissions:** AndroidManifest.xml shows INTERNET permission is declared but not used for data transmission
2. **Local Storage Only:** All data stored in encrypted SQLite database on device
3. **No Analytics:** No analytics SDKs (Google Analytics, Firebase, etc.) included
4. **No Third-Party Services:** No backend servers, APIs, or cloud services
5. **Encryption Implementation:** Uses cryptography package for XChaCha20-Poly1305
6. **Secure Storage:** Uses flutter_secure_storage for key management

---

## Third-Party SDKs Disclosure

While the app includes the following packages, NONE of them collect or transmit user data:

**Core Functionality:**
- `sqflite` - Local database (no network access)
- `flutter_secure_storage` - Secure key storage (local only)
- `cryptography` - Encryption library (local only)
- `encrypt` - Encryption utilities (local only)
- `crypto` - Cryptographic functions (local only)

**UI/UX:**
- `provider` - State management (no data collection)
- `mobile_scanner` - QR code scanning (local processing only)
- `qr_flutter` - QR code generation (local only)
- `font_awesome_flutter` - Icons (no data collection)
- `flutter_markdown` - Markdown rendering (no data collection)

**Device Features:**
- `local_auth` - Biometric authentication (local only)
- `permission_handler` - Permission management (no data collection)
- `safe_device` - Device security checks (local only)

**File Operations:**
- `file_picker` - File selection (local only)
- `share_plus` - File sharing (user-initiated only)
- `path_provider` - File paths (local only)

**Utilities:**
- `base32` - Base32 encoding (local only)
- `bcrypt` - Password hashing (local only)
- `shared_preferences` - Local preferences (local only)

**None of these packages transmit data to external servers.**

---

## Notes for Submission

1. **Be Consistent:** Ensure your answers match your Privacy Policy
2. **Be Honest:** Google can verify your claims through app analysis
3. **Update Regularly:** If you add features that collect data, update this form
4. **Keep Records:** Save this document for future reference and updates
5. **Review Period:** Google typically reviews Data Safety declarations within 1-3 days

---

**Prepared By:** Development Team  
**Review Date:** January 19, 2025  
**Next Review:** Before each app update

