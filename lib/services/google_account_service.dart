import 'package:flutter/services.dart';

/// Service to get Google account information from Android
/// 
/// Uses Android AccountManager to retrieve the primary Google account
/// that will be used for Android Auto Backup
class GoogleAccountService {
  static const MethodChannel _channel = MethodChannel('com.cdac.authenticator/google_account');
  
  /// Get the primary Google account email
  /// 
  /// Returns the email of the primary Google account signed in on the device,
  /// or null if no Google account is found or permission is denied
  static Future<String?> getPrimaryGoogleAccount() async {
    try {
      print('🔍 [GoogleAccount] Fetching primary Google account...');
      final String? account = await _channel.invokeMethod('getPrimaryGoogleAccount');
      
      if (account != null && account.isNotEmpty) {
        print('✅ [GoogleAccount] Found: $account');
        return account;
      } else {
        print('⚠️ [GoogleAccount] No Google account found');
        return null;
      }
    } on PlatformException catch (e) {
      print('❌ [GoogleAccount] Error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ [GoogleAccount] Unexpected error: $e');
      return null;
    }
  }

  /// Get all Google accounts available on the device
  /// 
  /// Returns a list of Google account emails signed in on the device,
  /// or empty list if no accounts found
  static Future<List<String>> getAllGoogleAccounts() async {
    try {
      print('🔍 [GoogleAccount] Fetching all Google accounts...');
      final List<dynamic>? accounts = await _channel.invokeMethod('getAllGoogleAccounts');
      
      if (accounts != null && accounts.isNotEmpty) {
        final result = List<String>.from(accounts);
        print('✅ [GoogleAccount] Found ${result.length} account(s)');
        return result;
      } else {
        print('⚠️ [GoogleAccount] No Google accounts found');
        return [];
      }
    } on PlatformException catch (e) {
      print('❌ [GoogleAccount] Error: ${e.message}');
      return [];
    } catch (e) {
      print('❌ [GoogleAccount] Unexpected error: $e');
      return [];
    }
  }
}
