import 'dart:async';

import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/totp_service.dart';
import '../services/account_service.dart';
//TODO -- Remove this file as otp function is also handled by account_view_model 
class OTPViewModel with ChangeNotifier {
  final TOTPService totpService;
  final AccountService accountService;
  List<AccountWithOTP> _accountsWithOTP = [];
  int _secondsRemaining = 30;
  Timer? _timer;

  OTPViewModel({
    required this.totpService,
    required this.accountService,
  }) {
    _startTimer();
  }

  List<AccountWithOTP> get accountsWithOTP => _accountsWithOTP;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining = totpService.getRemainingSeconds();
      
      if (_secondsRemaining == 30) {
        // Regenerate OTPs when timer resets
        _generateOTPs();
      } else {
        notifyListeners();
      }
    });
  }

  Future<void> _generateOTPs() async {
    try {
      final accounts = await accountService.getAllAccounts();
      _accountsWithOTP = accounts.map((account) {
        final otp = totpService.generateTOTP(account.secretKey);
        return AccountWithOTP(
          account: account,
          otp: otp,
          secondsRemaining: _secondsRemaining,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error generating OTPs: $e');
    }
  }

  void refreshOTPs() {
    _generateOTPs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}