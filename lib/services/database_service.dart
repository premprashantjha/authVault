import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import 'encryption_service.dart';

/// Database service for storing accounts with encrypted secrets
class DatabaseService {
  static Database? _database;
  static const String _dbName = 'authenticator.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'accounts';
  
  final EncryptionService _encryptionService;

  DatabaseService({EncryptionService? encryptionService})
      : _encryptionService = encryptionService ?? EncryptionService();

  Future<Database> get database async {
    if (_database != null) return _database!;
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
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        orderBy: 'createdAt DESC',
      );

      final List<Account> accounts = [];
      for (final map in maps) {
        try {
          // Decrypt secret key
          final encryptedSecret = map['secretKey'] as String;
          final decryptedSecret = await _encryptionService.decrypt(encryptedSecret);
          
          accounts.add(Account.fromMap({
            ...map,
            'secretKey': decryptedSecret,
          }));
        } catch (e) {
          debugPrint('Error decrypting account ${map['id']}: $e');
          // Skip corrupted accounts
        }
      }

      return accounts;
    } catch (e) {
      debugPrint('Error loading accounts: $e');
      return [];
    }
  }

  /// Add a new account
  Future<void> addAccount(Account account) async {
    try {
      final db = await database;
      
      // Encrypt secret key before storage
      final encryptedSecret = await _encryptionService.encrypt(account.secretKey);
      
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
    } on DatabaseException catch (e) {
      // Handle unique constraint violations explicitly
      final message = e.toString().toLowerCase();
      if (message.contains('unique') || message.contains('unique constraint')) {
        throw Exception('Account already exists');
      }
      debugPrint('Database error adding account: $e');
      throw Exception('Failed to add account');
    } catch (e) {
      debugPrint('Error adding account: $e');
      throw Exception('Failed to add account');
    }
  }

  /// Update an existing account
  Future<void> updateAccount(Account account) async {
    try {
      final db = await database;
      
      // Encrypt secret key before storage
      final encryptedSecret = await _encryptionService.encrypt(account.secretKey);
      
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
    } catch (e) {
      debugPrint('DatabaseService: Error updating account: $e');
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
    } catch (e) {
      debugPrint('DatabaseService: Error deleting account: $e');
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
      debugPrint('DatabaseService: Error checking account existence: $e');
      return false;
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
    } catch (e) {
      debugPrint('DatabaseService: Error clearing accounts: $e');
      throw Exception('Failed to clear accounts');
    }
  }
}

