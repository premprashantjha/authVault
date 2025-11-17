import 'package:authenticator/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:authenticator/view_models/account_view_model.dart';
import 'package:authenticator/models/account.dart';
import 'package:authenticator/services/totp_service.dart';
import 'package:authenticator/services/account_service.dart';

// Fake in-memory DatabaseService used only for tests. Overrides DB operations
class FakeDatabaseService extends DatabaseService {
  final List<Account> _store = [];

  FakeDatabaseService() : super(encryptionService: null);

  @override
  Future<List<Account>> getAllAccounts() async {
    return List<Account>.from(_store);
  }

  @override
  Future<void> addAccount(Account account) async {
    final exists = _store.any((a) => a.issuer == account.issuer && a.accountName == account.accountName);
    if (exists) throw Exception('Account already exists');
    _store.add(account);
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    _store.removeWhere((a) => a.id == accountId);
  }

  @override
  Future<bool> accountExists(String issuer, String accountName) async {
    return _store.any((a) => a.issuer == issuer && a.accountName == accountName);
  }

  @override
  Future<void> updateAccount(Account account) async {
    final idx = _store.indexWhere((a) => a.id == account.id);
    if (idx != -1) _store[idx] = account;
  }
}

// A simple in-memory fake for AccountService used by AccountViewModel in tests.
class FakeAccountService extends AccountService {
  final FakeDatabaseService _fakeDb = FakeDatabaseService();

  FakeAccountService() : super(databaseService: FakeDatabaseService());

  @override
  Future<List<Account>> getAllAccounts() async => _fakeDb.getAllAccounts();

  @override
  Future<void> addAccount(Account newAccount) async => _fakeDb.addAccount(newAccount);

  @override
  Future<void> deleteAccount(String accountId) async => _fakeDb.deleteAccount(accountId);

  @override
  Future<bool> accountExists(Account account) async => _fakeDb.accountExists(account.issuer, account.accountName);

  @override
  Future<void> updateAccount(Account updatedAccount) async => _fakeDb.updateAccount(updatedAccount);
}
 

void main() {
  test('manual add-account flow updates AccountViewModel and exposes the new account', () async {
    final fakeService = FakeAccountService();
    final totp = TOTPService();

    final viewModel = AccountViewModel(
      accountService: fakeService as dynamic,
      totpService: totp,
      autoInit: true,
    );

    // Wait until the initial load completes
    while (viewModel.isLoading) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    expect(viewModel.hasAccounts, isFalse);

    final account = Account(issuer: 'Test', accountName: 'user@example.com', secretKey: 'JBSWY3DPEHPK3PXP');

    final added = await viewModel.addAccount(account);
    expect(added, isTrue);

    // Wait for reload triggered by addAccount
    var attempts = 0;
    while (!viewModel.hasAccounts && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 20));
      attempts++;
    }

    expect(viewModel.hasAccounts, isTrue);
    expect(viewModel.accountsWithOTP.any((a) => a.account.accountName == 'user@example.com'), isTrue);

    // Try to add duplicate and ensure addAccount returns false
    final duplicate = Account(issuer: 'Test', accountName: 'user@example.com', secretKey: 'JBSWY3DPEHPK3PXP');
    final added2 = await viewModel.addAccount(duplicate);
    expect(added2, isFalse);
  });
}
