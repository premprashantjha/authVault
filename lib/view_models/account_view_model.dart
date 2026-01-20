import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../services/account_service.dart';
import '../services/totp_service.dart';

class AccountViewModel with ChangeNotifier {
  static const _favoriteAccountsKey = 'favorite_account_ids';

  final AccountService accountService;
  final TOTPService totpService;
  SharedPreferences? _prefs;

  List<Account> _accounts = [];
  List<AccountWithOTP> _accountsWithOTP = [];
  List<AccountWithOTP> _filteredAccounts = [];
  Timer? _timer;
  bool _isLoading = false;
  final Set<String> _favoriteAccountIds = <String>{};
  final Set<String> _selectedIssuers = <String>{};
  String _searchQuery = '';
  bool _favoritesOnly = false;

  /// If [autoInit] is true (default) the view model will load accounts
  /// and start the OTP timer immediately. Tests may set autoInit=false to
  /// avoid starting timers or hitting the database during widget tests.
  AccountViewModel({
    required this.accountService,
    required this.totpService,
    bool autoInit = true,
  }) {
    // Don't auto-load accounts - wait for explicit reloadAfterUnlock() call
    // This prevents showing data before authentication
    if (autoInit) {
      _startOTPTimer();
    }
    _loadFavorites();
  }

  /// Initialize and load accounts (called after authentication)
  Future<void> initialize() async {
    await reloadAfterUnlock();
  }

  List<Account> get accounts => _accounts;
  List<AccountWithOTP> get accountsWithOTP => _accountsWithOTP;
  List<AccountWithOTP> get filteredAccounts => _filteredAccounts;
  bool get isLoading => _isLoading;
  bool get hasAccounts => _accounts.isNotEmpty;
  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty || _selectedIssuers.isNotEmpty || _favoritesOnly;
  bool get hasFilterSelections => _selectedIssuers.isNotEmpty || _favoritesOnly;
  bool get favoritesOnly => _favoritesOnly;
  Set<String> get selectedIssuers => Set.unmodifiable(_selectedIssuers);
  int get totalAccountCount => _accounts.length;

  List<String> get issuerFilters {
    final Map<String, int> counts = {};
    for (final account in _accounts) {
      final issuer = account.issuer.trim();
      if (issuer.isEmpty) continue;
      counts[issuer] = (counts[issuer] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final compareCount = b.value.compareTo(a.value);
        if (compareCount != 0) return compareCount;
        return a.key.toLowerCase().compareTo(b.key.toLowerCase());
      });
    return entries.map((entry) => entry.key).toList();
  }

  Future<void> _loadAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedAccounts = await accountService.getAllAccounts();

      // Only update accounts if we successfully loaded data
      // This prevents clearing accounts on temporary errors
      if (loadedAccounts.isNotEmpty || _accounts.isEmpty) {
        _accounts = loadedAccounts;
        _generateOTPs();
      } else {
        // If load returned empty but we had accounts before, keep existing accounts
        // and just regenerate OTPs (this handles temporary database issues)
        if (kDebugMode) {
          debugPrint(
            '⚠️ [ViewModel] Loaded 0 accounts but had ${_accounts.length} before - keeping existing accounts',
          );
        }
        _generateOTPs();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ViewModel] Error loading accounts: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
      }
      // Don't clear accounts on error - keep existing data
      // This prevents the "0 accounts" bug when database has temporary issues
      if (_accounts.isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ [ViewModel] Keeping ${_accounts.length} existing accounts due to load error',
          );
        }
        _generateOTPs();
      } else {
        // Only clear if we truly have no accounts
        _accounts = [];
        _accountsWithOTP = [];
        _filteredAccounts = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAccount(Account account) async {
    try {
      print('=== ADD ACCOUNT ===');
      print('ADD ACCOUNT → AccountService: ${accountService.hashCode}');
      print(
        'ADD ACCOUNT → DatabaseService: ${accountService.databaseService.hashCode}',
      );

      await accountService.addAccount(account);

      // Ensure timer is running before loading accounts
      if (_timer == null) {
        _startOTPTimer();
      }

      // Reload accounts from database (this calls _generateOTPs and notifyListeners internally)
      await _loadAccounts();

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding account: $e');
      }
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    try {
      await accountService.deleteAccount(accountId);

      // Remove from local lists without full reload for smoother UX
      _accounts.removeWhere((account) => account.id == accountId);
      _accountsWithOTP.removeWhere((item) => item.account.id == accountId);
      _favoriteAccountIds.remove(accountId);

      _applyFilters();

      return true;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error deleting account', error: e, level: 1000);
      }
      return false;
    }
  }

  void _startOTPTimer() {
    _timer?.cancel();
    // Only regenerate OTPs when time step changes (every 30 seconds)
    // Don't notify listeners for every second tick
    int lastTimeStep = -1;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimeStep =
          (DateTime.now().millisecondsSinceEpoch / 1000).floor() ~/ 30;
      final secondsRemaining = totpService.getRemainingSeconds();

      if (currentTimeStep != lastTimeStep) {
        lastTimeStep = currentTimeStep;
        _generateOTPs();
      } else {
        _accountsWithOTP = _accountsWithOTP
            .map(
              (accountWithOTP) =>
                  accountWithOTP.copyWith(secondsRemaining: secondsRemaining),
            )
            .toList();
        _filteredAccounts = _filteredAccounts
            .map(
              (accountWithOTP) =>
                  accountWithOTP.copyWith(secondsRemaining: secondsRemaining),
            )
            .toList();
      }
    });
  }

  void _generateOTPs() {
    if (kDebugMode) {
      developer.log(
        'Generating OTPs for ${_accounts.length} accounts',
        level: 800,
      );
    }
    _accountsWithOTP = _accounts.map((account) {
      final otp = totpService.generateTOTP(account.secretKey);
      final secondsRemaining = totpService.getRemainingSeconds();
      return AccountWithOTP(
        account: account,
        otp: otp,
        secondsRemaining: secondsRemaining,
        isFavorite: _favoriteAccountIds.contains(account.id),
      );
    }).toList();
    if (kDebugMode) {
      developer.log(
        'Generated ${_accountsWithOTP.length} OTPs, calling notifyListeners()',
        level: 800,
      );
    }
    _applyFilters();
  }

  void _updateSecondsRemaining(int secondsRemaining) {
    _accountsWithOTP = _accountsWithOTP
        .map(
          (accountWithOTP) =>
              accountWithOTP.copyWith(secondsRemaining: secondsRemaining),
        )
        .toList();
    _applyFilters();
  }

  void refreshOTPs() {
    _generateOTPs();
  }

  Future<bool> accountExists(Account account) async {
    return await accountService.accountExists(account);
  }

  Future<bool> updateAccount(Account account) async {
    try {
      await accountService.updateAccount(account);
      await _loadAccounts();

      return true;
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error updating account', error: e, level: 1000);
      }
      return false;
    }
  }

  Future<void> reloadAfterUnlock() async {
    // Start OTP timer if not running
    if (_timer == null) {
      _startOTPTimer();
    }

    // Load accounts from database
    await _loadAccounts();
  }

  void purgeSensitiveData() {
    // Don't clear accounts list - just clear OTP codes
    // This prevents the empty state flicker when unlocking
    _accountsWithOTP = _accountsWithOTP
        .map((item) => item.copyWith(otp: '------', secondsRemaining: 0))
        .toList();
    _filteredAccounts = _filteredAccounts
        .map((item) => item.copyWith(otp: '------', secondsRemaining: 0))
        .toList();
    notifyListeners();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    _applyFilters();
  }

  void toggleIssuerFilter(String issuer) {
    if (_selectedIssuers.contains(issuer)) {
      _selectedIssuers.remove(issuer);
    } else {
      _selectedIssuers.add(issuer);
    }
    _applyFilters();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _favoritesOnly = false;
    _selectedIssuers.clear();
    _applyFilters();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    _applyFilters();
  }

  void setFilters({Set<String>? issuers, bool? favoritesOnly}) {
    if (issuers != null) {
      _selectedIssuers
        ..clear()
        ..addAll(issuers);
    }
    if (favoritesOnly != null) {
      _favoritesOnly = favoritesOnly;
    }
    _applyFilters();
  }

  Future<void> toggleFavorite(String accountId) async {
    await _ensurePrefs();
    if (_favoriteAccountIds.contains(accountId)) {
      _favoriteAccountIds.remove(accountId);
    } else {
      _favoriteAccountIds.add(accountId);
    }
    await _prefs?.setStringList(
      _favoriteAccountsKey,
      _favoriteAccountIds.toList(),
    );

    // Trigger reorder animation by applying filters with sort
    _applyFilters(skipSort: false);
  }

  Future<void> _loadFavorites() async {
    try {
      await _ensurePrefs();
      final stored = _prefs?.getStringList(_favoriteAccountsKey) ?? const [];
      _favoriteAccountIds
        ..clear()
        ..addAll(stored);
      _applyFilters();
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error loading favorites', error: e, level: 1000);
      }
    }
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  void _applyFilters({bool skipSort = false}) {
    List<AccountWithOTP> working = _accountsWithOTP
        .map(
          (item) => item.copyWith(
            isFavorite: _favoriteAccountIds.contains(item.account.id),
          ),
        )
        .toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      working = working.where((item) {
        final issuer = item.account.issuer.toLowerCase();
        final label = item.account.accountName.toLowerCase();
        return issuer.contains(query) || label.contains(query);
      }).toList();
    }

    if (_selectedIssuers.isNotEmpty) {
      working = working
          .where((item) => _selectedIssuers.contains(item.account.issuer))
          .toList();
    }

    if (_favoritesOnly) {
      working = working.where((item) => item.isFavorite).toList();
    }

    // Only sort if not skipped (skip during favorite toggle to keep items in place)
    if (!skipSort) {
      working.sort((a, b) {
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        return a.account.issuer.toLowerCase().compareTo(
          b.account.issuer.toLowerCase(),
        );
      });
    }

    _filteredAccounts = working;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
