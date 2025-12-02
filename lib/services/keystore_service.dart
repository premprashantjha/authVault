import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';

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
}
