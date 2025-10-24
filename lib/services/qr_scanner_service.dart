import 'dart:developer' as developer;

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

      final type = uriParts[0]; // totp or hotp
      final label = Uri.decodeComponent(uriParts[1]);
      final params = Uri.parse(uri).queryParameters;

      // 🎯 FIXED: Better label parsing logic
      String issuer = 'AuthVault';
      String accountName = 'Prem';

      if (label.contains(':')) {
        // Format: "Issuer:AccountName"
        final labelParts = label.split(':');
        issuer = labelParts[0].trim();
        accountName = labelParts[1].trim();
      } else {
        // Format: Just account name, issuer might be in params
        accountName = label.trim();
      }

      // 🎯 FIXED: Always prefer issuer from parameters if available
      if (params['issuer'] != null && params['issuer']!.isNotEmpty) {
        issuer = params['issuer']!.trim();
      }

      // If issuer is still empty, use account name as fallback
      if (issuer.isEmpty) {
        issuer = accountName.contains('@') 
            ? accountName.split('@')[1] // Extract domain from email
            : 'Unknown Service';
      }

      final secret = params['secret'] ?? '';
      if (secret.isEmpty) {
        throw FormatException('Missing secret parameter');
      }

      developer.log('QR Code parsed successfully', name: 'QRScanner');

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