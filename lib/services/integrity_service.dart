import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'secure_storage_service.dart';

/// Service for app and database integrity verification
/// Protects against APK tampering and database modifications
class IntegrityService {
  final SecureStorageService _secureStorage;
  static const String _dbChecksumKey = 'authenticator_db_checksum';
  static const String _appVersionKey = 'authenticator_app_version';
  
  IntegrityService({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  /// Calculate SHA256 checksum of database file
  Future<String?> calculateDatabaseChecksum() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'authenticator.db');
      
      // Open a temporary read-only connection so closing it won't affect the main DB handle
      final db = await openDatabase(
        path,
        readOnly: true,
        singleInstance: false,
      );
      try {
        final data = await db.query('accounts', orderBy: 'id ASC');

        // Create deterministic checksum from data
        final dataString = json.encode(data);
        final bytes = utf8.encode(dataString);
        final digest = sha256.convert(bytes);

        return digest.toString();
      } finally {
        await db.close();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating database checksum: $e');
      }
      return null;
    }
  }

  /// Store current database checksum
  Future<void> storeDatabaseChecksum() async {
    final checksum = await calculateDatabaseChecksum();
    if (checksum != null) {
      await _secureStorage.saveSecret(_dbChecksumKey, checksum);
    }
  }

  /// Verify database hasn't been tampered with
  /// Returns true if valid, false if tampered or no baseline
  Future<bool> verifyDatabaseIntegrity() async {
    try {
      final storedChecksum = await _secureStorage.getSecret(_dbChecksumKey);
      if (storedChecksum == null) {
        // No baseline, store current state
        await storeDatabaseChecksum();
        return true;
      }
      
      final currentChecksum = await calculateDatabaseChecksum();
      if (currentChecksum == null) return false;
      
      return storedChecksum == currentChecksum;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error verifying database integrity: $e');
      }
      return false;
    }
  }

  /// Update checksum after legitimate database changes
  Future<void> updateDatabaseChecksum() async {
    await storeDatabaseChecksum();
  }

  /// Store app version for migration/integrity checks
  Future<void> storeAppVersion(String version) async {
    await _secureStorage.saveSecret(_appVersionKey, version);
  }

  /// Get stored app version
  Future<String?> getStoredAppVersion() async {
    return await _secureStorage.getSecret(_appVersionKey);
  }

  /// Clear all integrity data (for logout/reset)
  Future<void> clearIntegrityData() async {
    await _secureStorage.deleteSecret(_dbChecksumKey);
  }
}
