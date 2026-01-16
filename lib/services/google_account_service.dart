import 'package:flutter/services.dart';

/// Service to get Google account information from Android
/// 
/// Uses Android AccountManager to retrieve the primary Google account
/// that will be used for Android Auto Backup
/// 
/// Optimized for authenticator apps:
/// - Checks only once per app session
/// - Minimal overhead for security-focused app
class GoogleAccountService {
  static const MethodChannel _channel = MethodChannel('com.cdac.authenticator/google_account');
  
  // Session cache - check only once per app session
  static bool _hasCheckedThisSession = false;
  static String? _cachedPrimaryAccount;
  static List<String>? _cachedAllAccounts;
  
  /// Get the primary Google account email
  /// 
  /// Returns the email of the primary Google account signed in on the device,
  /// or null if no Google account is found or permission is denied
  /// 
  /// Cached for entire app session - only checks once
  static Future<String?> getPrimaryGoogleAccount() async {
    // Return cached result if already checked this session
    if (_hasCheckedThisSession && _cachedPrimaryAccount != null) {
      print('✓ [GoogleAccount] Using session cache: $_cachedPrimaryAccount');
      return _cachedPrimaryAccount;
    }
    
    try {
      print('🔍 [GoogleAccount] Fetching primary Google account (first check this session)...');
      final String? account = await _channel.invokeMethod('getPrimaryGoogleAccount');
      
      if (account != null && account.isNotEmpty) {
        print('✅ [GoogleAccount] Found: $account');
        _cachedPrimaryAccount = account;
        _hasCheckedThisSession = true;
        return account;
      } else {
        print('⚠️ [GoogleAccount] No Google account found');
        _cachedPrimaryAccount = null;
        _hasCheckedThisSession = true;
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
  /// 
  /// Cached for entire app session - only checks once
  static Future<List<String>> getAllGoogleAccounts() async {
    // Return cached result if already checked this session
    if (_hasCheckedThisSession && _cachedAllAccounts != null) {
      print('✓ [GoogleAccount] Using session cache (${_cachedAllAccounts!.length} account(s))');
      return _cachedAllAccounts!;
    }
    
    try {
      print('🔍 [GoogleAccount] Fetching all Google accounts (first check this session)...');
      final List<dynamic>? accounts = await _channel.invokeMethod('getAllGoogleAccounts');
      
      if (accounts != null && accounts.isNotEmpty) {
        final result = List<String>.from(accounts);
        print('✅ [GoogleAccount] Found ${result.length} account(s)');
        _cachedAllAccounts = result;
        _hasCheckedThisSession = true;
        return result;
      } else {
        print('⚠️ [GoogleAccount] No Google accounts found');
        _cachedAllAccounts = [];
        _hasCheckedThisSession = true;
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
  
  /// Invalidate cache (call when user signs in/out of Google account)
  /// 
  /// This is rarely needed in authenticator apps since Google account
  /// changes are infrequent and require app restart anyway
  static void invalidateCache() {
    _hasCheckedThisSession = false;
    _cachedPrimaryAccount = null;
    _cachedAllAccounts = null;
    print('🔄 [GoogleAccount] Cache invalidated - will check on next request');
  }
}
