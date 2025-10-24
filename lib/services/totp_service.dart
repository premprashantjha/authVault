import 'dart:typed_data';
import 'package:base32/base32.dart';
import 'package:crypto/crypto.dart';

class TOTPService {
  static const int _timeStep = 30;

  String generateTOTP(String secret) {
    final key = base32.decode(secret);
    final time = (DateTime.now().millisecondsSinceEpoch / 1000).floor() ~/ _timeStep;
    final timeBytes = _intToBytes(time);
    
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

  Uint8List _intToBytes(int value) {
    return Uint8List(8)..setRange(0, 8, [
      value >> 56, value >> 48, value >> 40, value >> 32,
      value >> 24, value >> 16, value >> 8, value
    ].map((v) => v & 0xff));
  }

  int getRemainingSeconds() {
    return _timeStep - (DateTime.now().second % _timeStep);
  }

  bool validateSecret(String secret) {
    try {
      base32.decode(secret);
      return true;
    } catch (e) {
      return false;
    }
  }
}