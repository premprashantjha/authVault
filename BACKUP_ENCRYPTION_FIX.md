# Backup Encryption Fix

## Issue Identified

**Error Message:**
```
flutter: ❌ Backup decryption failed: EncryptionException: Authentication failed - data may be tampered
```

## Root Cause

The `LocalBackupService` had a **decryption mismatch**:

### What Was Happening:

1. **Backup Creation** (✅ Correct):
   ```dart
   // Line ~90: Creates backup with PASSWORD encryption
   final encryptedData = await _encryptionService.encryptWithPassword(jsonData, password);
   ```

2. **Backup Restore** (✅ Correct):
   ```dart
   // Line ~130: Restores with PASSWORD decryption
   jsonData = await _encryptionService.decryptWithPassword(encryptedData, password);
   ```

3. **Metadata Check** (❌ WRONG):
   ```dart
   // Line ~237: Tried to decrypt WITHOUT password (device-based encryption)
   final jsonData = await _encryptionService.decrypt(encryptedData);
   // This fails because backup was encrypted WITH password!
   ```

### The Problem:

`getBackupMetadata()` was trying to decrypt a **password-encrypted** backup using **device-based decryption** (no password). This caused authentication failure.

---

## Solution

### Changed `getBackupMetadata()` to NOT decrypt:

**Before (Broken):**
```dart
Future<Map<String, dynamic>?> getBackupMetadata() async {
  final encryptedData = await backupFile.readAsString();
  
  // ❌ WRONG: Tries to decrypt without password
  final jsonData = await _encryptionService.decrypt(encryptedData);
  
  final backupData = json.decode(jsonData);
  return {
    'account_count': backupData['accounts'].length,
    'timestamp': backupData['backup_timestamp'],
  };
}
```

**After (Fixed):**
```dart
Future<Map<String, dynamic>?> getBackupMetadata() async {
  final backupFile = await _getBackupFile();
  
  if (!await backupFile.exists()) {
    return null;
  }
  
  final stat = await backupFile.stat();
  
  // ✅ CORRECT: Returns file info WITHOUT decryption
  return {
    'file_exists': true,
    'file_size': stat.size,
    'last_modified': stat.modified,
    'account_count': null, // Cannot know without password
  };
}
```

### Why This Works:

1. **No decryption needed** - Just checks if file exists
2. **Returns basic file info** - Size, last modified date
3. **Account count unknown** - Can only be known after successful restore with password
4. **No authentication errors** - Doesn't try to decrypt

---

## Updated Restore Flow

### Before (Broken):
```
1. Check if backup exists ✅
2. Get metadata (decrypt without password) ❌ FAILS HERE
3. Show "Restore X accounts?" dialog
4. Ask for password
5. Restore
```

### After (Fixed):
```
1. Check if backup exists ✅
2. Show "Restore backup?" dialog (no account count) ✅
3. Ask for password ✅
4. Restore (decrypt with password) ✅
5. Show success with account count ✅
```

---

## Files Changed

### 1. `lib/services/local_backup_service.dart`
**Method:** `getBackupMetadata()`

**Changes:**
- Removed decryption attempt
- Returns file stats instead of decrypted content
- Added comment explaining why account_count is null

### 2. `lib/view/auto_backup_settings_screen.dart`
**Method:** `_restoreBackup()`

**Changes:**
- Removed metadata check for account count
- Simplified confirmation dialog (no account count shown)
- Added better error handling for password errors
- Shows account count AFTER successful restore

---

## Testing

### Test Case 1: Enable Backup
```
1. Enable Local Encrypted Backup
2. Set password: "test123"
3. Add 3 accounts
4. Check logs:
   ✅ "Local backup created: 3 accounts"
   ✅ "Local backup with password created successfully"
```

### Test Case 2: Check Metadata (Should NOT fail)
```
1. Open Local Encrypted Backup settings
2. Check logs:
   ✅ "Backup file exists"
   ✅ "File size: X bytes"
   ❌ NO "Authentication failed" error
```

### Test Case 3: Restore Backup
```
1. Tap "Restore from Local Backup"
2. Confirm restore
3. Enter password: "test123"
4. Check result:
   ✅ Accounts restored successfully
   ✅ No authentication errors
```

### Test Case 4: Wrong Password
```
1. Tap "Restore from Local Backup"
2. Enter wrong password: "wrong"
3. Check result:
   ✅ Shows "Incorrect password" error
   ✅ Can try again
```

---

## Why This Happened

### Design Issue:

The original code tried to show the account count BEFORE asking for password:

```
"Restore 5 accounts from backup?"
```

But to know the account count, it needs to decrypt the backup, which requires the password!

### Solution:

Show a generic message instead:

```
"Restore your accounts from local backup?"
```

Then show the account count AFTER successful restore:

```
"5 accounts restored successfully!"
```

---

## Encryption Methods Explained

### 1. Device-Based Encryption (Keystore)
```dart
// Encrypt
final encrypted = await encryptionService.encrypt(data);

// Decrypt
final decrypted = await encryptionService.decrypt(encrypted);
```

**Use Case:** 
- App's main data storage
- Tied to device hardware
- Cannot transfer to another device

### 2. Password-Based Encryption
```dart
// Encrypt
final encrypted = await encryptionService.encryptWithPassword(data, password);

// Decrypt
final decrypted = await encryptionService.decryptWithPassword(encrypted, password);
```

**Use Case:**
- Backups (local and manual)
- Can transfer to another device
- User must remember password

### The Rule:
**If you encrypt WITH password, you MUST decrypt WITH password!**

---

## Impact

### Before Fix:
- ❌ Metadata check always failed
- ❌ "Authentication failed" errors in logs
- ❌ Confusing for debugging
- ✅ Restore still worked (used correct decryption)

### After Fix:
- ✅ No authentication errors
- ✅ Clean logs
- ✅ Simpler code
- ✅ Restore works perfectly

---

## Lessons Learned

1. **Match encryption/decryption methods** - If you encrypt with password, decrypt with password
2. **Don't decrypt unnecessarily** - Metadata can be file stats, not decrypted content
3. **Password-protected data cannot be read without password** - Even for metadata
4. **Show account count AFTER restore** - Not before (requires password)

---

## Summary

**Problem:** `getBackupMetadata()` tried to decrypt password-encrypted backup without password

**Solution:** Changed to return file stats without decryption

**Result:** No more authentication errors, cleaner code, restore works perfectly

**Status:** ✅ FIXED
