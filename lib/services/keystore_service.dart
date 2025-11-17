import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

class KeystoreService {
  static const MethodChannel _channel = MethodChannel('authenticator/keystore');

  /// Ensure a keystore key exists with [alias]
  Future<bool> generateKey(String alias) async {
    final res = await _channel.invokeMethod<bool>('generateKey', {'alias': alias});
    return res ?? false;
  }

  /// Wrap [keyBytes] with keystore key identified by [alias]. Returns base64 wrapped bytes.
  Future<String> wrapKey(String alias, Uint8List keyBytes) async {
    final base64Key = base64Encode(keyBytes);
    final wrapped = await _channel.invokeMethod<String>('wrapKey', {'alias': alias, 'key': base64Key});
    return wrapped ?? '';
  }

  /// Unwrap the base64 wrapped key and return raw bytes
  Future<Uint8List> unwrapKey(String alias, String wrappedBase64) async {
    final unwrappedBase64 = await _channel.invokeMethod<String>('unwrapKey', {'alias': alias, 'wrapped': wrappedBase64});
    if (unwrappedBase64 == null || unwrappedBase64.isEmpty) {
      throw Exception('Failed to unwrap key');
    }
    return base64Decode(unwrappedBase64);
  }
}
