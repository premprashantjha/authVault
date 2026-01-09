import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DEPRECATED: Custom keystore service - replaced by flutter_secure_storage
/// 
/// This service is no longer used as flutter_secure_storage provides:
/// - Automatic Android Keystore integration
/// - Automatic iOS Keychain integration  
/// - Cross-platform compatibility
/// - Hardware-backed security when available
/// 
/// Keeping this file for backward compatibility during migration.
/// Will be removed in future versions.
@Deprecated('Use flutter_secure_storage via SecureStorageService instead')
class KeystoreService {
  static const MethodChannel _channel = MethodChannel('authenticator/keystore');

  @Deprecated('Use flutter_secure_storage instead')
  Future<bool> generateKey(String alias) async {
    if (kDebugMode) {
      debugPrint('⚠️ DEPRECATED: KeystoreService.generateKey() - Use flutter_secure_storage instead');
    }
    try {
      final res = await _channel.invokeMethod<bool>('generateKey', {'alias': alias});
      return res ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('KeystoreService.generateKey() failed: $e');
      }
      return false;
    }
  }

  @Deprecated('Use flutter_secure_storage instead')
  Future<Uint8List> wrapKey(String alias, Uint8List keyBytes) async {
    if (kDebugMode) {
      debugPrint('⚠️ DEPRECATED: KeystoreService.wrapKey() - Use flutter_secure_storage instead');
    }
    try {
      final base64Key = base64Encode(keyBytes);
      final wrappedBase64 = await _channel.invokeMethod<String>('wrapKey', {'alias': alias, 'key': base64Key});
      if (wrappedBase64 == null || wrappedBase64.isEmpty) {
        throw Exception('Keystore wrap returned empty result');
      }
      return base64Decode(wrappedBase64);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('KeystoreService.wrapKey() failed: $e');
      }
      rethrow;
    }
  }

  @Deprecated('Use flutter_secure_storage instead')
  Future<Uint8List> unwrapKey(String alias, Uint8List wrappedKeyBytes) async {
    if (kDebugMode) {
      debugPrint('⚠️ DEPRECATED: KeystoreService.unwrapKey() - Use flutter_secure_storage instead');
    }
    try {
      final wrappedBase64 = base64Encode(wrappedKeyBytes);
      final unwrappedBase64 = await _channel.invokeMethod<String>('unwrapKey', {'alias': alias, 'wrapped': wrappedBase64});
      if (unwrappedBase64 == null || unwrappedBase64.isEmpty) {
        throw Exception('Keystore unwrap returned empty result');
      }
      return base64Decode(unwrappedBase64);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('KeystoreService.unwrapKey() failed: $e');
      }
      rethrow;
    }
  }

  @Deprecated('Use flutter_secure_storage instead')
  Future<bool> isKeyHardwareBacked(String alias) async {
    if (kDebugMode) {
      debugPrint('⚠️ DEPRECATED: KeystoreService.isKeyHardwareBacked() - Use flutter_secure_storage instead');
    }
    try {
      final res = await _channel.invokeMethod<bool>('isKeyHardwareBacked', {'alias': alias});
      return res ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('KeystoreService.isKeyHardwareBacked() failed: $e');
      }
      return false;
    }
  }

  @Deprecated('Use flutter_secure_storage instead')
  Future<void> storeKey(String alias, Uint8List keyBytes) async {
    if (kDebugMode) {
      debugPrint('⚠️ DEPRECATED: KeystoreService.storeKey() - Use flutter_secure_storage instead');
    }
    // Implementation kept for backward compatibility but not recommended
  }

  @Deprecated('Use flutter_secure_storage instead')
  Future<Uint8List?> getKey(String alias) async {
    if (kDebugMode) {
      debugPrint('⚠️ DEPRECATED: KeystoreService.getKey() - Use flutter_secure_storage instead');
    }
    return null; // Return null to force migration to new system
  }

  @Deprecated('Use flutter_secure_storage instead')
  Future<void> deleteKey(String alias) async {
    if (kDebugMode) {
      debugPrint('⚠️ DEPRECATED: KeystoreService.deleteKey() - Use flutter_secure_storage instead');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wrapped_$alias');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('KeystoreService.deleteKey() failed: $e');
      }
    }
  }
}