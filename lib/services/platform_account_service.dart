import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to get platform account ID for encryption key derivation
/// 
/// Android: Google Account ID
/// iOS: Apple ID (iCloud account)
class PlatformAccountService {
  static const MethodChannel _channel = MethodChannel('com.cdac.authenticator/account');

  /// Get platform account ID
  /// 
  /// Returns account ID string that will be used for encryption key derivation
  /// This ensures backups are tied to the user's Google/Apple account
  Future<String> getAccountId() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidAccountId();
      } else if (Platform.isIOS) {
        return await _getAppleAccountId();
      } else {
        throw PlatformException(
          code: 'UNSUPPORTED_PLATFORM',
          message: 'Platform not supported',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting account ID: $e');
      }
      rethrow;
    }
  }

  /// Get Google Account ID (Android)
  Future<String> _getAndroidAccountId() async {
    try {
      final String? accountId = await _channel.invokeMethod('getGoogleAccountId');
      
      if (accountId == null || accountId.isEmpty) {
        throw PlatformException(
          code: 'NO_ACCOUNT',
          message: 'No Google account found. Please sign in to your Google account.',
        );
      }
      
      return accountId;
    } on PlatformException catch (e) {
      if (e.code == 'NO_ACCOUNT') {
        rethrow;
      }
      throw PlatformException(
        code: 'ACCOUNT_ERROR',
        message: 'Failed to get Google account: ${e.message}',
      );
    }
  }

  /// Get Apple ID (iOS)
  Future<String> _getAppleAccountId() async {
    try {
      final String? accountId = await _channel.invokeMethod('getAppleAccountId');
      
      if (accountId == null || accountId.isEmpty) {
        throw PlatformException(
          code: 'NO_ACCOUNT',
          message: 'No Apple ID found. Please sign in to iCloud.',
        );
      }
      
      return accountId;
    } on PlatformException catch (e) {
      if (e.code == 'NO_ACCOUNT') {
        rethrow;
      }
      throw PlatformException(
        code: 'ACCOUNT_ERROR',
        message: 'Failed to get Apple ID: ${e.message}',
      );
    }
  }

  /// Check if platform account is available
  Future<bool> isAccountAvailable() async {
    try {
      await getAccountId();
      return true;
    } catch (e) {
      return false;
    }
  }
}
