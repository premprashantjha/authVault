import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Service to generate and manage recovery codes
/// 
/// Recovery codes are one-time use codes that can be used to recover
/// access to the app if the user loses their device or account access
class RecoveryCodesService {
  static const String _recoveryCodesKey = 'recovery_codes_hashes';
  static const String _recoveryCodesGeneratedKey = 'recovery_codes_generated';
  static const int _codeCount = 10;
  static const int _codeLength = 8;

  /// Generate new recovery codes
  /// 
  /// Returns a list of recovery codes that should be shown to the user ONCE
  /// The codes are hashed before storage for security
  Future<List<String>> generateRecoveryCodes() async {
    final codes = <String>[];
    final hashes = <String>[];
    final random = Random.secure();

    // Generate codes
    for (int i = 0; i < _codeCount; i++) {
      final code = _generateCode(random);
      codes.add(code);
      hashes.add(_hashCode(code));
    }

    // Store hashes
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recoveryCodesKey, hashes);
    await prefs.setBool(_recoveryCodesGeneratedKey, true);

    return codes;
  }

  /// Verify a recovery code
  /// 
  /// Returns true if the code is valid and hasn't been used
  /// Marks the code as used after successful verification
  Future<bool> verifyRecoveryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final hashes = prefs.getStringList(_recoveryCodesKey) ?? [];

    if (hashes.isEmpty) {
      return false;
    }

    final codeHash = _hashCode(code);
    final index = hashes.indexOf(codeHash);

    if (index == -1) {
      return false;
    }

    // Remove the used code
    hashes.removeAt(index);
    await prefs.setStringList(_recoveryCodesKey, hashes);

    return true;
  }

  /// Check if recovery codes have been generated
  Future<bool> hasRecoveryCodes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_recoveryCodesGeneratedKey) ?? false;
  }

  /// Get remaining recovery codes count
  Future<int> getRemainingCodesCount() async {
    final prefs = await SharedPreferences.getInstance();
    final hashes = prefs.getStringList(_recoveryCodesKey) ?? [];
    return hashes.length;
  }

  /// Delete all recovery codes
  Future<void> deleteRecoveryCodes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recoveryCodesKey);
    await prefs.remove(_recoveryCodesGeneratedKey);
  }

  /// Generate a single recovery code
  String _generateCode(Random random) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude similar chars
    final code = List.generate(
      _codeLength,
      (index) => chars[random.nextInt(chars.length)],
    ).join();

    // Format as XXXX-XXXX for readability
    return '${code.substring(0, 4)}-${code.substring(4, 8)}';
  }

  /// Hash a recovery code for secure storage
  String _hashCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
