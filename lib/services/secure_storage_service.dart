import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();

  Future<void> saveSecret(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getSecret(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteSecret(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAllSecrets() async {
    await _storage.deleteAll();
  }
}