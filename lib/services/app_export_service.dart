import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/account.dart';

/// Service for exporting accounts using otpauth-migration URI format
/// Compatible with Google Authenticator and similar apps
class AppExportService {
  /// Generate otpauth-migration URI for accounts
  static String generateMigrationUri(List<Account> accounts) {
    if (accounts.isEmpty) {
      throw ArgumentError('Cannot generate URI for empty account list');
    }

    try {
      final protobufData = _encodeToProtobuf(accounts);
      final base64Data = base64UrlEncode(protobufData);
      return 'otpauth-migration://offline?data=$base64Data';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating migration URI: $e');
      }
      rethrow;
    }
  }

  /// Encode accounts to protobuf format
  static Uint8List _encodeToProtobuf(List<Account> accounts) {
    final buffer = <int>[];

    for (final account in accounts) {
      final accountData = _encodeOtpParameters(account);
      buffer.add((1 << 3) | 2);
      _writeVarint(buffer, accountData.length);
      buffer.addAll(accountData);
    }

    buffer.add((2 << 3) | 0);
    _writeVarint(buffer, 1);

    buffer.add((3 << 3) | 0);
    _writeVarint(buffer, accounts.length);

    buffer.add((4 << 3) | 0);
    _writeVarint(buffer, 0);

    buffer.add((5 << 3) | 0);
    _writeVarint(buffer, DateTime.now().millisecondsSinceEpoch);

    return Uint8List.fromList(buffer);
  }

  /// Encode a single account as OtpParameters
  static List<int> _encodeOtpParameters(Account account) {
    final buffer = <int>[];

    final secretBytes = _base32Decode(account.secretKey);
    buffer.add((1 << 3) | 2);
    _writeVarint(buffer, secretBytes.length);
    buffer.addAll(secretBytes);

    final name = '${account.issuer}:${account.accountName}';
    final nameBytes = utf8.encode(name);
    buffer.add((2 << 3) | 2);
    _writeVarint(buffer, nameBytes.length);
    buffer.addAll(nameBytes);

    final issuerBytes = utf8.encode(account.issuer);
    buffer.add((3 << 3) | 2);
    _writeVarint(buffer, issuerBytes.length);
    buffer.addAll(issuerBytes);

    buffer.add((4 << 3) | 0);
    _writeVarint(buffer, 0);

    buffer.add((5 << 3) | 0);
    _writeVarint(buffer, 1);

    buffer.add((6 << 3) | 0);
    _writeVarint(buffer, 1);

    return buffer;
  }

  /// Write a variable-length integer (varint)
  static void _writeVarint(List<int> buffer, int value) {
    while (value > 0x7f) {
      buffer.add((value & 0x7f) | 0x80);
      value >>= 7;
    }
    buffer.add(value & 0x7f);
  }

  /// Decode base32 string to bytes
  static Uint8List _base32Decode(String base32) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final cleanInput = base32.toUpperCase().replaceAll(RegExp(r'[^A-Z2-7]'), '');
    
    final bytes = <int>[];
    int buffer = 0;
    int bitsLeft = 0;

    for (int i = 0; i < cleanInput.length; i++) {
      final char = cleanInput[i];
      final value = alphabet.indexOf(char);
      
      if (value == -1) continue;

      buffer = (buffer << 5) | value;
      bitsLeft += 5;

      if (bitsLeft >= 8) {
        bytes.add((buffer >> (bitsLeft - 8)) & 0xff);
        bitsLeft -= 8;
      }
    }

    return Uint8List.fromList(bytes);
  }

  /// Check if a URI is an otpauth-migration URI
  static bool isMigrationUri(String uri) {
    return uri.startsWith('otpauth-migration://');
  }

  /// Get app-specific deep link
  static String getAppDeepLink() {
    return 'cdacauth://import';
  }
}
