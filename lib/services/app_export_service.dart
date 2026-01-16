import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/account.dart';

/// Service for exporting accounts using otpauth-migration URI format
/// This format is compatible with Google Authenticator and only works with
/// authenticator apps that support this protocol (not readable by Google Lens)
class AppExportService {
  /// Generate otpauth-migration URI for accounts
  /// This creates a URI that can only be opened by authenticator apps
  /// Format: otpauth-migration://offline?data=<base64_protobuf>
  static String generateMigrationUri(List<Account> accounts) {
    if (accounts.isEmpty) {
      throw ArgumentError('Cannot generate URI for empty account list');
    }

    try {
      // Encode accounts to protobuf-like structure
      final protobufData = _encodeToProtobuf(accounts);
      
      // Base64 encode the protobuf data
      final base64Data = base64UrlEncode(protobufData);
      
      // Create the migration URI
      return 'otpauth-migration://offline?data=$base64Data';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error generating migration URI: $e');
      }
      rethrow;
    }
  }

  /// Encode accounts to protobuf format (simplified version)
  /// This creates a binary format similar to Google Authenticator's export
  static Uint8List _encodeToProtobuf(List<Account> accounts) {
    final buffer = <int>[];

    for (final account in accounts) {
      // Encode each account as an OtpParameters message
      final accountData = _encodeOtpParameters(account);
      
      // Field 1 (OtpParameters) - wire type 2 (length-delimited)
      buffer.add((1 << 3) | 2); // Field number 1, wire type 2
      _writeVarint(buffer, accountData.length);
      buffer.addAll(accountData);
    }

    // Add version and batch information
    // Field 2 (version) - wire type 0 (varint)
    buffer.add((2 << 3) | 0);
    _writeVarint(buffer, 1); // Version 1

    // Field 3 (batch_size) - wire type 0 (varint)
    buffer.add((3 << 3) | 0);
    _writeVarint(buffer, accounts.length);

    // Field 4 (batch_index) - wire type 0 (varint)
    buffer.add((4 << 3) | 0);
    _writeVarint(buffer, 0); // First batch

    // Field 5 (batch_id) - wire type 0 (varint)
    buffer.add((5 << 3) | 0);
    _writeVarint(buffer, DateTime.now().millisecondsSinceEpoch);

    return Uint8List.fromList(buffer);
  }

  /// Encode a single account as OtpParameters
  static List<int> _encodeOtpParameters(Account account) {
    final buffer = <int>[];

    // Field 1: secret (bytes)
    final secretBytes = _base32Decode(account.secretKey);
    buffer.add((1 << 3) | 2); // Field 1, wire type 2
    _writeVarint(buffer, secretBytes.length);
    buffer.addAll(secretBytes);

    // Field 2: name (string) - format: issuer:account
    final name = '${account.issuer}:${account.accountName}';
    final nameBytes = utf8.encode(name);
    buffer.add((2 << 3) | 2); // Field 2, wire type 2
    _writeVarint(buffer, nameBytes.length);
    buffer.addAll(nameBytes);

    // Field 3: issuer (string)
    final issuerBytes = utf8.encode(account.issuer);
    buffer.add((3 << 3) | 2); // Field 3, wire type 2
    _writeVarint(buffer, issuerBytes.length);
    buffer.addAll(issuerBytes);

    // Field 4: algorithm (enum) - 0=SHA1, 1=SHA256, 2=SHA512
    buffer.add((4 << 3) | 0); // Field 4, wire type 0
    _writeVarint(buffer, 0); // SHA1 (default)

    // Field 5: digits (enum) - 1=6 digits, 2=8 digits
    buffer.add((5 << 3) | 0); // Field 5, wire type 0
    _writeVarint(buffer, 1); // 6 digits (default)

    // Field 6: type (enum) - 0=HOTP, 1=TOTP
    buffer.add((6 << 3) | 0); // Field 6, wire type 0
    _writeVarint(buffer, 1); // TOTP

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

  /// Get app-specific deep link for our app
  /// This would be registered in AndroidManifest.xml and Info.plist
  static String getAppDeepLink() {
    return 'cdacauth://import'; // Our custom scheme
  }
}
