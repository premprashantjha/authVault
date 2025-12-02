import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

class TOTPService {
  static const int _timeStep = 30;

  String generateTOTP(String secret) {
    return generateTOTPAtTime(secret, DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  /// Generate TOTP for a specific unix time (seconds)
  String generateTOTPAtTime(String secret, int unixTimeSeconds) {
    final cleanSecret = secret.trim().toUpperCase().replaceAll(' ', '');
    final key = base32.decode(cleanSecret);
    final counter = unixTimeSeconds ~/ _timeStep;
    final timeBytes = _intToBytes(counter);

    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(timeBytes);
    final hash = digest.bytes;

    final offset = hash[hash.length - 1] & 0xf;
    final code = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    return '${code % 1000000}'.padLeft(6, '0');
  }

  /// Validate a user-entered code against the secret allowing a window of
  /// ±[timeSteps] time steps (each step is _timeStep seconds).
  /// Returns true if any code in the window matches.
  bool validateTOTP(String secret, String code, {int timeSteps = 1}) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (int i = -timeSteps; i <= timeSteps; i++) {
      final t = now + (i * _timeStep);
      final expected = generateTOTPAtTime(secret, t);
      if (expected == code) return true;
    }
    return false;
  }

  Uint8List _intToBytes(int value) {
    final bytes = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xff;
      value = value >> 8;
    }
    return bytes;
  }

  int getRemainingSeconds() {
    final epochSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final secondsIntoStep = epochSeconds % _timeStep;
    return _timeStep - secondsIntoStep;
  }

  bool validateSecret(String secret) {
    try {
      final cleanSecret = secret.trim().toUpperCase().replaceAll(' ', '');
      if (kDebugMode) {
        debugPrint('TOTPService: Validating secret: "$secret" -> "$cleanSecret" (length: ${cleanSecret.length})');
      }
      final decoded = base32.decode(cleanSecret);
      if (kDebugMode) {
        debugPrint('TOTPService: Secret validation successful, decoded length: ${decoded.length}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TOTPService: Secret validation failed: $e');
      }
      return false;
    }
  }
}