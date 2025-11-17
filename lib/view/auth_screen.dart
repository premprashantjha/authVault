import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../services/auth_service.dart';
import '../widgets/animated/animated_button.dart';

class AuthScreen extends StatefulWidget {
  final AuthService authService;
  final VoidCallback onAuthenticated;

  const AuthScreen({
    super.key,
    required this.authService,
    required this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _pinController = TextEditingController();
  bool _isAuthenticating = false;
  String? _errorMessage;
  bool _obscurePin = true;
  bool _biometricAttempted = false;
  bool _showPin = true;

  @override
  void initState() {
    super.initState();
    // Defer biometric attempt until after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
  }
  
  Future<Map<String, dynamic>> _checkBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('authenticator_biometric_enabled') ?? false;
    final available = enabled ? await widget.authService.isBiometricStillAvailable() : false;
    return {'enabled': enabled, 'available': available};
  }

  Future<void> _tryBiometricAuth() async {
    // Check if biometric is enabled and available
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('authenticator_biometric_enabled') ?? false;
    if (!biometricEnabled) {
      // Do not show biometric UI; show PIN immediately
      setState(() {
        _showPin = true;
        _biometricAttempted = true;
      });
      return;
    }

    final available = await widget.authService.isBiometricStillAvailable();
    if (!available) {
      // Biometric not available - show message and allow PIN entry
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication is not available. Please use PIN.';
          _showPin = true;
          _biometricAttempted = true;
        });
      }
      return;
    }
    // Attempt biometric and only show PIN if biometric fails or is cancelled
    if (mounted) setState(() {
      _isAuthenticating = true;
      _showPin = false; // hide PIN while biometric prompt runs
    });

    try {
      final success = await widget.authService.authenticateWithBiometric();
      if (!mounted) return;
      if (success) {
        widget.onAuthenticated();
        return;
      }
      // Biometric failed or cancelled - show PIN
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Biometric authentication failed or cancelled. Please use PIN.';
        _showPin = true;
        _biometricAttempted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Biometric authentication error. Please use PIN.';
        _showPin = true;
        _biometricAttempted = true;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_pinController.text.length < 4) {
      setState(() {
        _errorMessage = 'PIN must be at least 4 digits';
      });
      return;
    }

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    try {
      // When authenticating via PIN, skip biometric to avoid re-opening the prompt
      final success = await widget.authService.authenticate(
        pin: _pinController.text,
        skipBiometric: true,
      );

      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });

        if (success) {
          HapticFeedback.lightImpact();
          widget.onAuthenticated();
        } else {
          // Check for lockout or failed attempts
          final failedAttempts = await widget.authService.getFailedAttempts();
          final remainingLockout = await widget.authService.getRemainingLockoutMinutes();
          
          if (remainingLockout != null) {
            setState(() {
              _errorMessage = 'Account locked. Try again in $remainingLockout minutes.';
            });
          } else {
            final remainingAttempts = 5 - failedAttempts;
            setState(() {
              _errorMessage = remainingAttempts > 0
                  ? 'Invalid PIN. $remainingAttempts attempts remaining.'
                  : 'Invalid PIN. Please try again.';
            });
          }
          _pinController.clear();
          HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      // Handle lockout exception
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        _pinController.clear();
        HapticFeedback.heavyImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Authenticator',
                  style: AppTheme.headlineLarge(theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your PIN to continue',
                  style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),
                
                // PIN Input (hidden until biometric attempt completes or if biometrics unavailable)
                if (_showPin) TextField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: AppTheme.headlineMedium(theme.colorScheme.onSurface).copyWith(
                    letterSpacing: 8,
                    fontSize: 32,
                  ),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: '••••',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin ? Icons.visibility : Icons.visibility_off,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      onPressed: () {
                        setState(() => _obscurePin = !_obscurePin);
                      },
                    ),
                  ),
                  onSubmitted: (_) => _authenticate(),
                ),
                
                // Error Message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: AppTheme.bodyMedium(AppTheme.errorColor),
                    textAlign: TextAlign.center,
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Authenticate Button
                if (_showPin)
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedButton(
                      onTap: _isAuthenticating ? null : _authenticate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _isAuthenticating ? Colors.grey : AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _isAuthenticating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Authenticate', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Biometric Button (only show if enabled and available)
                // If biometric is enabled and available, show an explicit Biometric button
                FutureBuilder<Map<String, dynamic>>(
                  future: _checkBiometricStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!;
                      final isEnabled = data['enabled'] as bool;
                      final isAvailable = data['available'] as bool;

                      if (isEnabled && isAvailable) {
                        // Only show the button when PIN is visible (user opted to retry) or biometric attempt was done
                        return (_showPin || _biometricAttempted)
                            ? TextButton.icon(
                                onPressed: _isAuthenticating ? null : _tryBiometricAuth,
                                icon: const Icon(Icons.fingerprint),
                                label: const Text('Use Biometric'),
                              )
                            : const SizedBox.shrink();
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}

