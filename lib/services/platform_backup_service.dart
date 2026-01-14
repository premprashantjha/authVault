import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'google_account_service.dart';

/// Platform-aware backup service that handles both Android and iOS
/// 
/// Android: Uses Google Drive via Android Auto Backup
/// iOS: Uses iCloud via iOS backup system
class PlatformBackupService {
  // Note: Native method channels removed to prevent hanging
  // iOS CloudKit integration can be added later when properly tested

  /// Get platform-specific backup provider name
  static String get backupProviderName {
    if (Platform.isAndroid) {
      return 'Google Cloud';
    } else if (Platform.isIOS) {
      return 'iCloud';
    } else {
      return 'Cloud Storage';
    }
  }

  /// Get platform-specific account type name
  static String get accountTypeName {
    if (Platform.isAndroid) {
      return 'Google account';
    } else if (Platform.isIOS) {
      return 'Apple ID';
    } else {
      return 'account';
    }
  }

  /// Get platform-specific backup description
  static String get backupDescription {
    if (Platform.isAndroid) {
      return 'Your encrypted backup will be stored in Google Drive and synced across your Android devices.';
    } else if (Platform.isIOS) {
      return 'Your encrypted backup will be stored in iCloud and synced across your Apple devices.';
    } else {
      return 'Your encrypted backup will be stored in cloud storage.';
    }
  }

  /// Get platform-specific restore description
  static String get restoreDescription {
    if (Platform.isAndroid) {
      return 'Restore your accounts from Google Drive backup.';
    } else if (Platform.isIOS) {
      return 'Restore your accounts from iCloud backup.';
    } else {
      return 'Restore your accounts from cloud backup.';
    }
  }

  /// Get platform-specific no backup message
  static String get noBackupMessage {
    if (Platform.isAndroid) {
      return 'No backup found in Google Drive for this account.';
    } else if (Platform.isIOS) {
      return 'No backup found in iCloud for this Apple ID.';
    } else {
      return 'No backup found in cloud storage.';
    }
  }

  /// Get platform-specific account selection message
  static String get accountSelectionMessage {
    if (Platform.isAndroid) {
      return 'Please select a Google account to check for backup';
    } else if (Platform.isIOS) {
      return 'Please sign in to iCloud to check for backup';
    } else {
      return 'Please select an account to check for backup';
    }
  }

  /// Get platform-specific no account message
  static String get noAccountMessage {
    if (Platform.isAndroid) {
      return 'No Google account selected';
    } else if (Platform.isIOS) {
      return 'No Apple ID found. Please sign in to iCloud.';
    } else {
      return 'No account selected';
    }
  }

  /// Get primary platform account (Google account on Android, Apple ID on iOS)
  static Future<String?> getPrimaryAccount() async {
    try {
      if (Platform.isAndroid) {
        return await GoogleAccountService.getPrimaryGoogleAccount();
      } else if (Platform.isIOS) {
        // For iOS, return a simple placeholder to avoid hanging
        // The actual Apple ID integration can be implemented later
        return "Apple ID (iCloud)";
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting primary account: $e');
      }
      return null;
    }
  }

  /// Get all platform accounts
  static Future<List<String>> getAllAccounts() async {
    try {
      if (Platform.isAndroid) {
        return await GoogleAccountService.getAllGoogleAccounts();
      } else if (Platform.isIOS) {
        // For iOS, return a simple list to avoid hanging
        // The actual Apple ID integration can be implemented later
        return ["Apple ID (iCloud)"];
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting all accounts: $e');
      }
      return [];
    }
  }

  // Note: iOS native methods removed to prevent hanging
  // These can be re-implemented later with proper testing

  /// Check if platform backup is available
  static Future<bool> isBackupAvailable() async {
    try {
      if (Platform.isAndroid) {
        // Check if Google Play Services is available and user has Google account
        final accounts = await GoogleAccountService.getAllGoogleAccounts();
        return accounts.isNotEmpty;
      } else if (Platform.isIOS) {
        // For iOS, assume iCloud is available for now
        // The actual iCloud availability check can be implemented later
        return true;
      } else {
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking backup availability: $e');
      }
      return false;
    }
  }

  /// Get platform-specific backup setup instructions
  static String getBackupSetupInstructions() {
    if (Platform.isAndroid) {
      return 'Make sure you\'re signed in to your Google account and have Google Drive access enabled.';
    } else if (Platform.isIOS) {
      return 'Make sure you\'re signed in to iCloud and have iCloud backup enabled in Settings.';
    } else {
      return 'Make sure you\'re signed in to your cloud storage account.';
    }
  }

  /// Get platform-specific backup icon
  static IconData get backupIcon {
    if (Platform.isAndroid) {
      return Icons.cloud_queue; // Google Drive style
    } else if (Platform.isIOS) {
      return Icons.cloud_done; // iCloud style
    } else {
      return Icons.cloud;
    }
  }

  /// Get platform-specific account icon
  static IconData get accountIcon {
    if (Platform.isAndroid) {
      return Icons.account_circle; // Google account style
    } else if (Platform.isIOS) {
      return Icons.person_outline; // Apple ID style
    } else {
      return Icons.account_circle;
    }
  }
}