import 'dart:convert';
import '../models/account.dart';
import 'secure_storage_service.dart';

class AccountService {
  final SecureStorageService secureStorage;
  static const String _accountsKey = 'authvault_accounts';

  AccountService({required this.secureStorage});

  Future<List<Account>> getAllAccounts() async {
    try {
      final accountsJson = await secureStorage.getSecret(_accountsKey);
      
      if (accountsJson == null || accountsJson.isEmpty) {
        return [];
      }
      
      // SIMPLE JSON decoding
      final List<dynamic> jsonList = json.decode(accountsJson);
      return jsonList.map((json) => Account.fromMap(json)).toList();
      
    } catch (e) {
      print('Error loading accounts: $e');
      return [];
    }
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    try {
      // SIMPLE JSON encoding
      final jsonList = accounts.map((account) => account.toMap()).toList();
      final accountsJson = json.encode(jsonList);
      
      await secureStorage.saveSecret(_accountsKey, accountsJson);
    } catch (e) {
      print('Error saving accounts: $e');
      throw Exception('Failed to save accounts');
    }
  }

  Future<void> addAccount(Account newAccount) async {
    final accounts = await getAllAccounts();
    
    // Check for duplicates
    final exists = accounts.any((account) => 
      account.issuer == newAccount.issuer && 
      account.accountName == newAccount.accountName
    );
    
    if (exists) {
      throw Exception('Account already exists');
    }

    accounts.add(newAccount);
    await saveAccounts(accounts);
  }

  Future<void> deleteAccount(String accountId) async {
    final accounts = await getAllAccounts();
    accounts.removeWhere((account) => account.id == accountId);
    await saveAccounts(accounts);
  }
}