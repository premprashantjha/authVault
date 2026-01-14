import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import 'encryption_service.dart';
import 'integrity_service.dart';

/// Database service for storing accounts with encrypted secrets
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'authenticator.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'accounts';
  
  final EncryptionService _encryptionService;
  final IntegrityService _integrityService;

  DatabaseService({
    EncryptionService? encryptionService,
    IntegrityService? integrityService,
  })  : _encryptionService = encryptionService ?? EncryptionService(),
        _integrityService = integrityService ?? IntegrityService();

  Future<Database> get database async {
    // Check if existing database is still valid and open
    if (_database != null) {
      try {
        // Verify the database is still open and accessible
        if (_database!.isOpen) {
          // Quick test query to ensure database is responsive
          await _database!.rawQuery('SELECT 1');
          return _database!;
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ [DatabaseService] Database was closed, reinitializing...');
          }
          _database = null;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ [DatabaseService] Database connection test failed: $e');
        }
        _database = null;
      }
    }
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        issuer TEXT NOT NULL,
        accountName TEXT NOT NULL,
        secretKey TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        UNIQUE(issuer, accountName)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here
    if (oldVersion < newVersion) {
      // Add migration logic if needed
    }
  }

  /// Get all accounts
  Future<List<Account>> getAllAccounts() async {
    print('=== DatabaseService.getAllAccounts() ===');
    print('DB QUERY → DatabaseService: $hashCode');
    
    try {
      // Ensure database is initialized and accessible
      final db = await database;
      
      // Verify database is open and accessible
      if (!db.isOpen) {
        if (kDebugMode) {
          debugPrint('⚠️ [DatabaseService] Database is not open, reinitializing...');
        }
        _database = null;
        final reopenedDb = await database;
        if (!reopenedDb.isOpen) {
          throw Exception('Failed to reopen database');
        }
      }
      
      print('DB PATH → ${db.path}');
      print('DB OPEN → ${db.isOpen}');
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'createdAt DESC',
      );

      print('Query returned ${maps.length} rows');

      final List<Account> accounts = [];
      
      for (final map in maps) {
        try {
          // Decrypt secret key (bind to issuer|accountName as AAD)
          final encryptedSecret = map['secretKey'] as String;
          final associatedData = '${map['issuer']}|${map['accountName']}';
          
          final decryptedSecret = await _encryptionService.decrypt(
            encryptedSecret,
            associatedData: associatedData,
          );

          accounts.add(Account.fromMap({
            ...map,
            'secretKey': decryptedSecret,
          }));
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ [DatabaseService] Error decrypting account ${map['issuer']}: $e');
          }
          // Skip corrupted accounts but continue processing others
        }
      }

      print('Successfully decrypted ${accounts.length} accounts');

      return accounts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [DatabaseService] Error loading accounts: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
      }
      // Rethrow the error so the caller can handle it appropriately
      // Don't silently return empty list - let the ViewModel decide what to do
      rethrow;
    }
  }

  /// Verify database integrity before loading
  Future<bool> verifyIntegrity() async {
    return await _integrityService.verifyDatabaseIntegrity();
  }

  /// Add a new account
  Future<void> addAccount(Account account) async {
    try {
      final db = await database;
      
      // Encrypt secret key before storage and bind ciphertext to issuer|accountName
      final associatedData = '${account.issuer}|${account.accountName}';
      final encryptedSecret = await _encryptionService.encrypt(
        account.secretKey,
        associatedData: associatedData,
      );
      
      await db.insert(
        _tableName,
        {
          'id': account.id,
          'issuer': account.issuer,
          'accountName': account.accountName,
          'secretKey': encryptedSecret, // Store encrypted
          'createdAt': account.createdAt.millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
      
      // Update integrity checksum after modification
      await _integrityService.updateDatabaseChecksum();
    } on DatabaseException catch (e) {
      // Handle unique constraint violations explicitly
      final message = e.toString().toLowerCase();
      if (message.contains('unique') || message.contains('unique constraint')) {
        throw Exception('Account already exists');
      }
      if (kDebugMode) {
        debugPrint('Database error adding account: $e');
      }
      throw Exception('Failed to add account');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding account: $e');
      }
      throw Exception('Failed to add account');
    }
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    try {
      final db = await database;
      
      // Encrypt secret key before storage and bind ciphertext to issuer|accountName
      final associatedData = '${account.issuer}|${account.accountName}';
      final encryptedSecret = await _encryptionService.encrypt(
        account.secretKey,
        associatedData: associatedData,
      );
      
      await db.update(
        _tableName,
        {
          'issuer': account.issuer,
          'accountName': account.accountName,
          'secretKey': encryptedSecret,
        },
        where: 'id = ?',
        whereArgs: [account.id],
      );
      
      // Update integrity checksum after modification
      await _integrityService.updateDatabaseChecksum();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DatabaseService: Error updating account: $e');
      }
      throw Exception('Failed to update account');
    }
  }

  /// Delete an account
  Future<void> deleteAccount(String accountId) async {
    try {
      final db = await database;
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [accountId],
      );
      
      // Update integrity checksum after modification
      await _integrityService.updateDatabaseChecksum();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DatabaseService: Error deleting account: $e');
      }
      throw Exception('Failed to delete account');
    }
  }

  /// Check if account exists
  Future<bool> accountExists(String issuer, String accountName) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'issuer = ? AND accountName = ?',
        whereArgs: [issuer, accountName],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DatabaseService: Error checking account existence: $e');
      }
      return false;
    }
  }

  /// Get an account by issuer and accountName (returns decrypted secret)
  Future<Account?> getAccountByIssuerAndName(String issuer, String accountName) async {
    try {
      final db = await database;
      final result = await db.query(
        _tableName,
        where: 'issuer = ? AND accountName = ?',
        whereArgs: [issuer, accountName],
        limit: 1,
      );

      if (result.isEmpty) return null;

      final map = result.first;
      try {
        final encryptedSecret = map['secretKey'] as String;
        final associatedData = '${map['issuer']}|${map['accountName']}';
        final decryptedSecret = await _encryptionService.decrypt(
          encryptedSecret,
          associatedData: associatedData,
        );
        return Account.fromMap({
          ...map,
          'secretKey': decryptedSecret,
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('DatabaseService: Error decrypting account ${map['id']}: $e');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DatabaseService: Error fetching account by issuer/name: $e');
      }
      return null;
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all accounts (for testing/reset)
  Future<void> clearAllAccounts() async {
    try {
      final db = await database;
      await db.delete(_tableName);
      
      // Update integrity checksum after modification
      await _integrityService.updateDatabaseChecksum();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DatabaseService: Error clearing accounts: $e');
      }
      throw Exception('Failed to clear accounts');
    }
  }
}

