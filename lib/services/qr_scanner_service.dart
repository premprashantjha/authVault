import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class OTPAuthURI {
  final String type;
  final String issuer;
  final String account;
  final String secret;
  final String? algorithm;
  final int? digits;
  final int? period;

  OTPAuthURI({
    required this.type,
    required this.issuer,
    required this.account,
    required this.secret,
    this.algorithm = 'SHA1',
    this.digits = 6,
    this.period = 30,
  });

  factory OTPAuthURI.fromString(String uri) {
  try {
    if (!uri.startsWith('otpauth://')) {
      throw FormatException('Invalid OTPAuth URI format');
    }

    final uriParts = uri.replaceFirst('otpauth://', '').split('/');
    if (uriParts.length < 2) {
      throw FormatException('Invalid OTPAuth URI structure');
    }

    final type = uriParts[0];
    final label = Uri.decodeComponent(uriParts[1]);
    final params = Uri.parse(uri).queryParameters;

    String issuer = '';
    String accountName = '';

    if (label.contains(':')) {
      final labelParts = label.split(':');
      issuer = labelParts[0].trim();
      accountName = labelParts[1].trim();
    } else {
      accountName = label.trim();
    }

    if (accountName.contains('?')) {
      accountName = accountName.split('?')[0].trim();
    }

    if (params['issuer'] != null && params['issuer']!.isNotEmpty) {
      issuer = params['issuer']!.trim();
    }

    if (issuer.isEmpty) {
      if (accountName.contains('@')) {
        issuer = accountName.split('@')[1].split('.')[0];
        issuer = issuer[0].toUpperCase() + issuer.substring(1);
      } else {
        issuer = 'Unknown Service';
      }
    }

    final secret = params['secret'] ?? '';
    if (secret.isEmpty) {
      throw FormatException('Missing secret parameter');
    }

    if (kDebugMode) {
      developer.log('QR Code parsed successfully', name: 'QRScanner');
    }

    return OTPAuthURI(
      type: type,
      issuer: issuer,
      account: accountName,
      secret: secret,
      algorithm: params['algorithm'],
      digits: params['digits'] != null ? int.tryParse(params['digits']!) : 6,
      period: params['period'] != null ? int.tryParse(params['period']!) : 30,
    );
  } catch (e) {
    throw FormatException('Failed to parse OTPAuth URI: $e');
  }
}

  bool get isValid => secret.isNotEmpty && account.isNotEmpty;
}