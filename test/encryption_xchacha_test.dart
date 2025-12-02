import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/services/encryption_service.dart';
import 'package:authenticator/services/secure_storage_service.dart';

class InMemorySecureStorage extends SecureStorageService {
  final Map<String, String> _store = {};

  @override
  Future<void> saveSecret(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> getSecret(String key) async {
    return _store[key];
  }

  @override
  Future<void> deleteSecret(String key) async {
    _store.remove(key);
  }
}

void main() {
  test('encrypt/decrypt roundtrip with XChaCha20-Poly1305', () async {
    final storage = InMemorySecureStorage();
    final svc = EncryptionService(secureStorage: storage);

    final plain = 'hello-secret-123';
    final aad = 'issuer|account';

    final encrypted = await svc.encrypt(plain, associatedData: aad);
    expect(encrypted, isNotNull);

    final decrypted = await svc.decrypt(encrypted, associatedData: aad);
    expect(decrypted, equals(plain));
  });
}
