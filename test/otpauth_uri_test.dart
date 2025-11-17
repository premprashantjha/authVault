import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/services/qr_scanner_service.dart';

void main() {
  group('OTPAuthURI parsing', () {
    test('parses typical otpauth URI with issuer param', () {
      final uri = 'otpauth://totp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30';
      final parsed = OTPAuthURI.fromString(uri);

      expect(parsed.type, equals('totp'));
      expect(parsed.issuer, equals('Example'));
      expect(parsed.account, equals('alice@example.com'));
      expect(parsed.secret, equals('JBSWY3DPEHPK3PXP'));
      expect(parsed.digits, equals(6));
      expect(parsed.period, equals(30));
    });

    test('throws on missing secret', () {
      final uri = 'otpauth://totp/NoSecret?issuer=NoSecret';
      expect(() => OTPAuthURI.fromString(uri), throwsFormatException);
    });
  });
}
