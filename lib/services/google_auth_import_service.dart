import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/account.dart';

/// Service for importing accounts from Google Authenticator export format
/// Supports the otpauth-migration:// URI scheme
class GoogleAuthImportService {
  /// Parse Google Authenticator migration URI
  /// Format: otpauth-migration://offline?data=base64_protobuf
  static List<ImportedAccount> parseMigrationUri(String uri) {
    if (!uri.startsWith('otpauth-migration://')) {
      throw FormatException('Not a Google Authenticator migration URI');
    }

    try {
      final parsedUri = Uri.parse(uri);
      final data = parsedUri.queryParameters['data'];
      
      if (data == null || data.isEmpty) {
        throw FormatException('Missing data parameter in migration URI');
      }

      // Decode base64
      final bytes = base64Decode(data);
      
      // Parse the protobuf-like structure
      return _parseProtobufPayload(bytes);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error parsing migration URI: $e');
      }
      throw FormatException('Failed to parse migration data: $e');
    }
  }

  /// Parse the protobuf payload from Google Authenticator
  static List<ImportedAccount> _parseProtobufPayload(List<int> bytes) {
    final accounts = <ImportedAccount>[];
    int offset = 0;

    if (kDebugMode) {
      debugPrint('Parsing protobuf payload, total bytes: ${bytes.length}');
    }

    while (offset < bytes.length) {
      if (offset >= bytes.length) break;
      
      // Read field tag and wire type
      final tagByte = bytes[offset];
      final fieldNumber = tagByte >> 3;
      final wireType = tagByte & 0x07;
      offset++;

      if (kDebugMode) {
        debugPrint('Field number: $fieldNumber, Wire type: $wireType, Offset: $offset');
      }

      // Field 1 is the OtpParameters message (repeated)
      if (fieldNumber == 1 && wireType == 2) { // Wire type 2 = length-delimited
        // Read length
        final lengthResult = _readVarintWithSize(bytes, offset);
        final length = lengthResult.value;
        offset = lengthResult.newOffset;
        
        if (kDebugMode) {
          debugPrint('OtpParameters length: $length');
        }
        
        if (offset + length > bytes.length) {
          if (kDebugMode) {
            debugPrint('Invalid length, breaking');
          }
          break;
        }
        
        // Parse OtpParameters
        final accountData = bytes.sublist(offset, offset + length);
        final account = _parseOtpParameters(accountData);
        
        if (account != null) {
          accounts.add(account);
          if (kDebugMode) {
            debugPrint('Successfully parsed account: ${account.issuer}');
          }
        }
        
        offset += length;
      } else {
        // Skip unknown fields
        if (wireType == 0) { // Varint
          final result = _readVarintWithSize(bytes, offset);
          offset = result.newOffset;
        } else if (wireType == 2) { // Length-delimited
          final lengthResult = _readVarintWithSize(bytes, offset);
          offset = lengthResult.newOffset + lengthResult.value;
        } else {
          // Unknown wire type, stop parsing
          break;
        }
      }
    }

    if (kDebugMode) {
      debugPrint('Total accounts parsed: ${accounts.length}');
    }

    return accounts;
  }

  /// Parse individual OtpParameters message
  static ImportedAccount? _parseOtpParameters(List<int> bytes) {
    String? secret;
    String? name;
    String? issuer;
    String algorithm = 'SHA1';
    int digits = 6;
    String type = 'totp';
    int counter = 0;

    int offset = 0;
    
    if (kDebugMode) {
      debugPrint('Parsing OtpParameters, bytes: ${bytes.length}');
    }

    while (offset < bytes.length) {
      if (offset >= bytes.length) break;
      
      final tagByte = bytes[offset];
      final fieldNumber = tagByte >> 3;
      final wireType = tagByte & 0x07;
      offset++;

      if (kDebugMode) {
        debugPrint('  Field: $fieldNumber, Wire: $wireType');
      }

      switch (fieldNumber) {
        case 1: // secret (bytes)
          if (wireType == 2) {
            final lengthResult = _readVarintWithSize(bytes, offset);
            final length = lengthResult.value;
            offset = lengthResult.newOffset;
            
            if (offset + length <= bytes.length) {
              secret = base32Encode(bytes.sublist(offset, offset + length));
              offset += length;
              if (kDebugMode) {
                debugPrint('  Secret length: $length');
              }
            }
          }
          break;

        case 2: // name (string)
          if (wireType == 2) {
            final lengthResult = _readVarintWithSize(bytes, offset);
            final length = lengthResult.value;
            offset = lengthResult.newOffset;
            
            if (offset + length <= bytes.length) {
              name = utf8.decode(bytes.sublist(offset, offset + length));
              offset += length;
              if (kDebugMode) {
                debugPrint('  Name: $name');
              }
            }
          }
          break;

        case 3: // issuer (string)
          if (wireType == 2) {
            final lengthResult = _readVarintWithSize(bytes, offset);
            final length = lengthResult.value;
            offset = lengthResult.newOffset;
            
            if (offset + length <= bytes.length) {
              issuer = utf8.decode(bytes.sublist(offset, offset + length));
              offset += length;
              if (kDebugMode) {
                debugPrint('  Issuer: $issuer');
              }
            }
          }
          break;

        case 4: // algorithm (enum)
          if (wireType == 0) {
            final result = _readVarintWithSize(bytes, offset);
            algorithm = _algorithmFromEnum(result.value);
            offset = result.newOffset;
          }
          break;

        case 5: // digits (enum)
          if (wireType == 0) {
            final result = _readVarintWithSize(bytes, offset);
            digits = _digitsFromEnum(result.value);
            offset = result.newOffset;
          }
          break;

        case 6: // type (enum)
          if (wireType == 0) {
            final result = _readVarintWithSize(bytes, offset);
            type = _typeFromEnum(result.value);
            offset = result.newOffset;
          }
          break;

        case 7: // counter (int64)
          if (wireType == 0) {
            final result = _readVarintWithSize(bytes, offset);
            counter = result.value;
            offset = result.newOffset;
          }
          break;

        default:
          // Skip unknown field
          if (wireType == 0) {
            final result = _readVarintWithSize(bytes, offset);
            offset = result.newOffset;
          } else if (wireType == 2) {
            final lengthResult = _readVarintWithSize(bytes, offset);
            offset = lengthResult.newOffset + lengthResult.value;
          } else {
            // Unknown wire type
            if (kDebugMode) {
              debugPrint('  Unknown wire type: $wireType');
            }
            return null;
          }
      }
    }

    if (secret == null || secret.isEmpty) {
      if (kDebugMode) {
        debugPrint('  No secret found, skipping account');
      }
      return null;
    }

    // Parse name to extract account and issuer if not provided
    String accountName = name ?? 'Unknown';
    if (issuer == null || issuer.isEmpty) {
      if (name != null && name.contains(':')) {
        final parts = name.split(':');
        issuer = parts[0].trim();
        accountName = parts[1].trim();
      } else {
        issuer = name ?? 'Imported';
      }
    }

    return ImportedAccount(
      issuer: issuer,
      accountName: accountName,
      secret: secret,
      algorithm: algorithm,
      digits: digits,
      type: type,
      counter: counter,
    );
  }

  /// Read variable-length integer (varint) and return new offset
  static VarintResult _readVarintWithSize(List<int> bytes, int offset) {
    int result = 0;
    int shift = 0;
    int startOffset = offset;
    
    while (offset < bytes.length) {
      final byte = bytes[offset];
      result |= (byte & 0x7f) << shift;
      offset++;
      
      if ((byte & 0x80) == 0) {
        break;
      }
      
      shift += 7;
      
      // Prevent infinite loop
      if (shift > 63) {
        break;
      }
    }
    
    return VarintResult(result, offset);
  }

  /// Read variable-length integer (varint) - legacy method
  static int _readVarint(List<int> bytes, int offset) {
    return _readVarintWithSize(bytes, offset).value;
  }

  /// Get size of varint
  static int _varintSize(int value) {
    if (value == 0) return 1;
    int size = 0;
    while (value > 0) {
      size++;
      value >>= 7;
    }
    return size;
  }

  /// Convert algorithm enum to string
  static String _algorithmFromEnum(int value) {
    switch (value) {
      case 0:
        return 'SHA1';
      case 1:
        return 'SHA256';
      case 2:
        return 'SHA512';
      case 3:
        return 'MD5';
      default:
        return 'SHA1';
    }
  }

  /// Convert digits enum to int
  static int _digitsFromEnum(int value) {
    switch (value) {
      case 1:
        return 6;
      case 2:
        return 8;
      default:
        return 6;
    }
  }

  /// Convert type enum to string
  static String _typeFromEnum(int value) {
    switch (value) {
      case 0:
        return 'hotp';
      case 1:
        return 'totp';
      default:
        return 'totp';
    }
  }

  /// Encode bytes to base32
  static String base32Encode(List<int> bytes) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final result = StringBuffer();
    
    int buffer = 0;
    int bitsLeft = 0;
    
    for (final byte in bytes) {
      buffer = (buffer << 8) | byte;
      bitsLeft += 8;
      
      while (bitsLeft >= 5) {
        result.write(alphabet[(buffer >> (bitsLeft - 5)) & 0x1f]);
        bitsLeft -= 5;
      }
    }
    
    if (bitsLeft > 0) {
      result.write(alphabet[(buffer << (5 - bitsLeft)) & 0x1f]);
    }
    
    return result.toString();
  }
}

/// Represents an imported account
class ImportedAccount {
  final String issuer;
  final String accountName;
  final String secret;
  final String algorithm;
  final int digits;
  final String type;
  final int counter;

  ImportedAccount({
    required this.issuer,
    required this.accountName,
    required this.secret,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.type = 'totp',
    this.counter = 0,
  });

  /// Convert to Account model
  Account toAccount() {
    return Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      issuer: issuer,
      accountName: accountName,
      secretKey: secret,
    );
  }

  @override
  String toString() {
    return 'ImportedAccount(issuer: $issuer, account: $accountName, type: $type)';
  }
}

/// Helper class for varint reading
class VarintResult {
  final int value;
  final int newOffset;

  VarintResult(this.value, this.newOffset);
}
