import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../app/theme.dart';
import '../services/auth_service.dart';

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

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _pinController = TextEditingController();
  bool _isAuthenticating = false;
  String? _errorMessage;
  bool _showPin = false; // Start hidden
  double _lockIconScale = 1.0; // For subtle pulse animation
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;
  int _failedAttempts = 0;
  int? _lockoutMinutes;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize shake animation for errors
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 8)
      .chain(CurveTween(curve: Curves.elasticIn))
      .animate(_shakeController!);
    
    // Load existing failed attempts and lockout status
    _updateAttemptsStatus();
    
    // Defer biometric attempt until after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
    // Subtle pulse animation for lock icon during biometric
    _startLockPulse();
  }

  void _startLockPulse() async {
    while (mounted && !_showPin) {
      if (mounted) {
        setState(() => _lockIconScale = 1.05);
      }
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _lockIconScale = 1.0);
      }
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }
  
  Future<void> _updateAttemptsStatus() async {
    final failedAttempts = await widget.authService.getFailedAttempts();
    final lockoutMinutes = await widget.authService.getRemainingLockoutMinutes();
    if (mounted) {
      setState(() {
        _failedAttempts = failedAttempts;
        _lockoutMinutes = lockoutMinutes;
      });
      
      // Start countdown timer if locked, stop if not locked
      if (lockoutMinutes != null && lockoutMinutes > 0) {
        _startLockoutCountdown();
      } else {
        _stopLockoutCountdown();
      }
    }
  }
  
  void _startLockoutCountdown() {
    // Cancel existing timer if any
    _lockoutTimer?.cancel();
    
    // Update every minute
    _lockoutTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _updateAttemptsStatus();
      
      // If lockout expired, stop timer and clear error message
      if (_lockoutMinutes == null || _lockoutMinutes == 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _errorMessage = null;
            _failedAttempts = 0;
          });
        }
      }
    });
  }
  
  void _stopLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
  }
  
  Future<Map<String, dynamic>> _checkBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('authenticator_biometric_enabled') ?? false;
    final available = enabled ? await widget.authService.isBiometricStillAvailable() : false;
    return {'enabled': enabled, 'available': available};
  }

  Future<void> _tryBiometricAuth() async {
    // Check if account is currently locked
    await _updateAttemptsStatus();
    if (_lockoutMinutes != null) {
      // Account is locked, show PIN screen with lockout message
      if (mounted) {
        setState(() {
          _errorMessage = 'Account locked. Try again in $_lockoutMinutes minute${_lockoutMinutes! > 1 ? 's' : ''}.';
          _showPin = true;
        });
      }
      return;
    }
    
    // Check if biometric is enabled and available
    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled = prefs.getBool('authenticator_biometric_enabled') ?? false;
    if (!biometricEnabled) {
      // Show PIN with smooth fade in
      if (mounted) {
        setState(() => _showPin = true);
      }
      return;
    }

    final available = await widget.authService.isBiometricStillAvailable();
    if (!available) {
      // Biometric not available - show PIN
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication is not available. Please use PIN.';
          _showPin = true;
        });
      }
      return;
    }

    try {
      final success = await widget.authService.authenticateWithBiometric();
      if (!mounted) return;
      if (success) {
        // Smooth transition - no loading indicators
        widget.onAuthenticated();
        return;
      }
      // Biometric failed or cancelled - show PIN
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Biometric authentication failed or cancelled. Please use PIN.';
        _showPin = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Biometric authentication error. Please use PIN.';
        _showPin = true;
      });
    }
  }

  Future<void> _authenticate() async {
    if (_pinController.text.length != 6) {
      setState(() {
        _errorMessage = 'PIN must be exactly 6 digits';
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
          // Auth service already incremented the counter, so fetch updated value
          await _updateAttemptsStatus();
          final remaining = 5 - _failedAttempts;
          setState(() {
            _errorMessage = remaining > 0 
                ? 'Incorrect PIN. $_failedAttempts/5 attempts used. $remaining remaining.'
                : 'Too many failed attempts.';
          });
          _pinController.clear();
          HapticFeedback.heavyImpact();
          // Trigger shake animation
          _shakeController?.forward().then((_) => _shakeController?.reset());
        }
      }
    } catch (e) {
      // Handle lockout exception
      if (mounted) {
        await _updateAttemptsStatus();
        setState(() {
          _isAuthenticating = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        _pinController.clear();
        HapticFeedback.heavyImpact();
        _shakeController?.forward().then((_) => _shakeController?.reset());
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
                // Logo/Icon with subtle pulse during biometric
                AnimatedScale(
                  scale: _lockIconScale,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 52,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title - always visible
                Text(
                  'Authenticator',
                  style: AppTheme.headlineLarge(theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                
                // Subtitle changes based on biometric state
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    key: ValueKey(_showPin),
                    _showPin ? 'Enter your PIN to continue' : 'Authenticating...',
                    style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Lockout status or attempts counter
                if (_showPin && _lockoutMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 32, right: 32),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_clock,
                            color: theme.colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Account locked. Try again in $_lockoutMinutes minute${_lockoutMinutes! > 1 ? 's' : ''}.',
                              style: AppTheme.bodyMedium(theme.colorScheme.error).copyWith(
                                fontSize: 13,
                                fontWeight: AppTheme.weightMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_showPin && _failedAttempts > 0 && _lockoutMinutes == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 32, right: 32),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Failed attempts: $_failedAttempts/5',
                        style: AppTheme.caption(theme.colorScheme.error).copyWith(
                          fontSize: 12,
                          fontWeight: AppTheme.weightMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                
                // Clean PIN input field
                if (_showPin && _lockoutMinutes == null)
                  AnimatedBuilder(
                    animation: _shakeAnimation ?? const AlwaysStoppedAnimation(0),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation?.value ?? 0, 0),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: TextField(
                        controller: _pinController,
                        autofocus: true,
                        enabled: _lockoutMinutes == null,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        obscureText: true,
                        obscuringCharacter: '●',
                        style: AppTheme.headlineMedium(theme.colorScheme.onSurface).copyWith(
                          fontSize: 24,
                          fontWeight: AppTheme.weightSemiBold,
                          letterSpacing: 12,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: '●  ●  ●  ●  ●  ●',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                            letterSpacing: 4,
                            fontSize: 16,
                          ),
                          counterText: '',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.error,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          // Haptic feedback on each digit
                          if (value.isNotEmpty) {
                            HapticFeedback.selectionClick();
                          }
                          if (_errorMessage != null) {
                            setState(() => _errorMessage = null);
                          }
                          // Auto-submit when 6 digits entered
                          if (value.length == 6) {
                            Future.delayed(const Duration(milliseconds: 200), () {
                              if (mounted && _pinController.text.length == 6) {
                                _authenticate();
                              }
                            });
                          }
                        },
                      ),
                    ),
                  ),
                
                // Error Message with animation
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 32, right: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTheme.bodyMedium(theme.colorScheme.error).copyWith(
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // Biometric Button - Platform-aware design
                FutureBuilder<Map<String, dynamic>>(
                  future: _checkBiometricStatus(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data!;
                      final isEnabled = data['enabled'] as bool;
                      final isAvailable = data['available'] as bool;

                      if (isEnabled && isAvailable && _showPin) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: _BiometricButton(
                            onPressed: _isAuthenticating ? null : _tryBiometricAuth,
                            isAuthenticating: _isAuthenticating,
                          ),
                        );
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
    _shakeController?.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }
}

// Biometric Button with platform-aware design
class _BiometricButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isAuthenticating;

  const _BiometricButton({
    required this.onPressed,
    this.isAuthenticating = false,
  });

  @override
  State<_BiometricButton> createState() => _BiometricButtonState();
}

class _BiometricButtonState extends State<_BiometricButton> {
  bool _isPressed = false;

  // Platform detection for biometric type
  String get _biometricText {
    // On iOS/macOS, prefer Face ID terminology, on Android use Fingerprint
    if (Theme.of(context).platform == TargetPlatform.iOS || 
        Theme.of(context).platform == TargetPlatform.macOS) {
      return 'Unlock with Face ID';
    }
    return 'Unlock with Fingerprint';
  }

  IconData get _biometricIcon {
    if (Theme.of(context).platform == TargetPlatform.iOS || 
        Theme.of(context).platform == TargetPlatform.macOS) {
      return Icons.face;
    }
    return Icons.fingerprint;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          color: theme.colorScheme.primary.withValues(alpha: 0.05),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed == null || widget.isAuthenticating
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onPressed!();
                  },
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(28),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _biometricIcon,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _biometricText,
                    style: AppTheme.bodyMedium(theme.colorScheme.primary).copyWith(
                      fontWeight: AppTheme.weightSemiBold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


