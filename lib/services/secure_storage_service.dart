import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service with platform-specific security options
/// Uses hardware-backed secure storage (Keychain/Keystore)
class SecureStorageService {
  // Android-specific options for maximum security
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    resetOnError: true,
  );

  // iOS-specific options for maximum security
  // Using default accessibility (whenUnlocked) - most secure option
  static const IOSOptions _iosOptions = IOSOptions(
    synchronizable: false, // Don't sync across devices for security
  );

  // macOS-specific options
  static const MacOsOptions _macOsOptions = MacOsOptions(
    synchronizable: false, // Don't sync across devices for security
  );

  static const _storage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
    mOptions: _macOsOptions,
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );

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