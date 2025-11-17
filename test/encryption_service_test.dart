import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/services/encryption_service.dart';
import 'package:authenticator/services/secure_storage_service.dart';
import 'package:flutter/services.dart';

/// Test double for SecureStorageService that keeps secrets in-memory.
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

  @override
  Future<void> clearAllSecrets() async {
    _store.clear();
  }
}

void main() {
  // Ensure Flutter bindings are initialized so platform channels and
  // ServicesBinding used by platform plugins work in unit tests.
  TestWidgetsFlutterBinding.ensureInitialized();
  group('EncryptionService', () {
    // Mock the platform keystore method channel so tests can run without
    // a real native implementation.
    const MethodChannel keystoreChannel = MethodChannel('authenticator/keystore');
    setUpAll(() {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(keystoreChannel, (call) async {
        final args = call.arguments as Map?;
        switch (call.method) {
          case 'generateKey':
            return true;
          case 'wrapKey':
            // Identity wrap for tests: return provided base64 key
            return args?['key'] as String? ?? '';
          case 'unwrapKey':
            // Identity unwrap for tests: return provided wrapped bytes
            return args?['wrapped'] as String? ?? '';
          default:
            return null;
        }
      });
    });
    tearDownAll(() {
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(keystoreChannel, null);
    });
    test('encrypt then decrypt returns original text', () async {
      final storage = InMemorySecureStorage();
      final service = EncryptionService(secureStorage: storage);

      final plain = 'this is a SECRET tok3n: 123456';
      final encrypted = await service.encrypt(plain);
      expect(encrypted, isNotNull);
      expect(encrypted, isNot(plain));

      final decrypted = await service.decrypt(encrypted);
      expect(decrypted, equals(plain));
    });

    test('different IV produces different ciphertexts', () async {
      final storage = InMemorySecureStorage();
      final service = EncryptionService(secureStorage: storage);

      final plain = 'repeatable text';
      final c1 = await service.encrypt(plain);
      final c2 = await service.encrypt(plain);

      expect(c1, isNot(equals(c2)), reason: 'Encryption with random IV should produce different ciphertexts');
    });
  });
}
