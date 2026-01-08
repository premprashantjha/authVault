import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KeystoreService {
  static const MethodChannel _channel = MethodChannel('authenticator/keystore');

  /// Ensure a keystore key exists with [alias]
  Future<bool> generateKey(String alias) async {
    final res = await _channel.invokeMethod<bool>('generateKey', {'alias': alias});
    return res ?? false;
  }

  /// Wrap [keyBytes] with keystore key identified by [alias]. Returns base64 wrapped bytes.
  Future<Uint8List> wrapKey(String alias, Uint8List keyBytes) async {
    final base64Key = base64Encode(keyBytes);
    final wrappedBase64 = await _channel.invokeMethod<String>('wrapKey', {'alias': alias, 'key': base64Key});
    if (wrappedBase64 == null || wrappedBase64.isEmpty) {
      throw Exception('Keystore wrap returned empty result');
    }
    return base64Decode(wrappedBase64);
  }

  /// Unwrap the base64 wrapped key and return raw bytes
  Future<Uint8List> unwrapKey(String alias, Uint8List wrappedBytes) async {
    final wrappedBase64 = base64Encode(wrappedBytes);
    final unwrappedBase64 = await _channel.invokeMethod<String>('unwrapKey', {'alias': alias, 'wrapped': wrappedBase64});
    if (unwrappedBase64 == null || unwrappedBase64.isEmpty) {
      throw Exception('Failed to unwrap key');
    }
    return base64Decode(unwrappedBase64);
  }

  /// Returns true if the keystore key identified by [alias] is hardware-backed
  /// (e.g. inside Android StrongBox / Secure Enclave) where detectable.
  Future<bool> isKeyHardwareBacked(String alias) async {
    final res = await _channel.invokeMethod<bool>('isKeyHardwareBacked', {'alias': alias});
    return res ?? false;
  }

  /// Store a key in the keystore (wraps and stores locally)
  /// This is used for storing the random DEK with backup enabled
  Future<void> storeKey(String alias, Uint8List keyBytes) async {
    print('=== KeystoreService.storeKey($alias) ===');
    print('Key to wrap: ${keyBytes.length} bytes');
    print('Key hash: ${keyBytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}...');
    
    final wrappedKey = await wrapKey(alias, keyBytes);
    print('✓ Key wrapped: ${wrappedKey.length} bytes');
    
    // Store wrapped key in SharedPreferences (will be backed up by OS)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wrapped_$alias', base64Encode(wrappedKey));
    print('✓ Wrapped key stored in SharedPreferences');
  }

  /// Get a key from the keystore (retrieves and unwraps)
  /// Returns null if key doesn't exist or unwrap fails
  /// 
  /// If unwrap fails, the incompatible wrapped key is automatically deleted
  /// so a fresh key can be generated
  Future<Uint8List?> getKey(String alias) async {
    print('=== KeystoreService.getKey($alias) ===');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final wrappedBase64 = prefs.getString('wrapped_$alias');
      
      if (wrappedBase64 == null) {
        print('❌ No wrapped key found in SharedPreferences for alias: $alias');
        return null;
      }
      
      print('✓ Wrapped key found in SharedPreferences (${wrappedBase64.length} chars)');
      final wrappedKey = base64Decode(wrappedBase64);
      print('Wrapped key decoded: ${wrappedKey.length} bytes');
      
      try {
        print('Attempting to unwrap key with keystore...');
        final unwrappedKey = await unwrapKey(alias, wrappedKey);
        print('✓ Successfully unwrapped key (${unwrappedKey.length} bytes)');
        print('Unwrapped key hash: ${unwrappedKey.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join()}...');
        return unwrappedKey;
      } catch (unwrapError) {
        // ❌ CRITICAL: Unwrap failed - KEK is missing or incompatible
        // This happens when:
        // 1. App was reinstalled (KEK deleted from AndroidKeyStore)
        // 2. Device keystore was reset
        // 3. Biometric enrollment changed (if setInvalidatedByBiometricEnrollment was set)
        
        print('❌ Unwrap failed: $unwrapError');
        print('❌ CRITICAL: KEK is missing or incompatible');
        print('❌ Wrapped DEK exists but cannot be unwrapped');
        print('❌ This means data encrypted with this DEK is LOST');
        
        // ✅ CORRECT BEHAVIOR: DO NOT auto-delete wrapped DEK
        // The wrapped DEK should only be deleted when:
        // 1. User explicitly resets the app
        // 2. User uninstalls the app (OS handles this)
        // 
        // ❌ WRONG: Auto-deleting and regenerating DEK
        // This causes permanent data loss because old backups can never be decrypted
        
        print('⚠️ Wrapped DEK preserved - will not auto-delete');
        print('⚠️ User must manually reset backup or reinstall app');
        
        // Return null to signal that DEK is unavailable
        // Caller should handle this by showing error to user
        return null;
      }
    } catch (e) {
      print('❌ Error in getKey: $e');
      return null;
    }
  }

  /// Delete a key from the keystore
  /// ⚠️ WARNING: Only call this when user explicitly resets backup
  /// This will make all backups encrypted with this DEK unrecoverable
  Future<void> deleteKey(String alias) async {
    print('⚠️ WARNING: Deleting wrapped DEK for alias: $alias');
    print('⚠️ All backups encrypted with this DEK will be LOST');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wrapped_$alias');
    print('✓ Wrapped DEK deleted');
  }
}
