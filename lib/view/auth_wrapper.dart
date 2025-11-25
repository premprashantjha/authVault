import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../services/auth_service.dart';
import '../view_models/account_view_model.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

/// Wrapper that handles app-level authentication
/// Features:
/// - Automatic re-lock when app goes to background
/// - Timeout-based re-lock (5 minutes)
/// - Rate limiting protection
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  AuthService? _authService;
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  bool _authEnabled = false;
  bool _showPrivacyOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle app lifecycle changes (background/foreground)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _showPrivacyShield();
    } else if (state == AppLifecycleState.resumed) {
      _dismissPrivacyShield();
      if (_authService != null && _authEnabled) {
        _checkAndRelock();
      }
    }
  }

  Future<void> _checkAndRelock() async {
    if (_authService == null || !_authEnabled) return;
    
    final shouldRelock = await _authService!.shouldRelock();
    if (shouldRelock && mounted) {
      context.read<AccountViewModel>().purgeSensitiveData();
      setState(() {
        _isAuthenticated = false; // Re-lock the app
      });
    } else if (!shouldRelock) {
      // Update unlock time to prevent immediate re-lock
      await _authService!.updateLastUnlockTime();
    }
  }

  Future<void> _initializeAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs: prefs);
      
      // Validate auth state first (handles edge cases like biometric becoming unavailable)
      await authService.validateAuthState();
      
      final authEnabled = await authService.isAuthEnabled();

      if (mounted) {
        setState(() {
          _authService = authService;
          _authEnabled = authEnabled;
          _isInitialized = true;
          // If auth is not enabled, allow direct access
          if (!authEnabled) {
            _isAuthenticated = true;
            _showPrivacyOverlay = false;
          } else {
            // Check if should re-lock on startup
            _checkAndRelock();
          }
        });
      }
    } catch (e) {
      // If initialization fails, allow access (graceful degradation)
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isAuthenticated = true;
        });
      }
    }
  }

  void _onAuthenticated() async {
    // Update unlock time when authenticated
    if (_authService != null) {
      await _authService!.updateLastUnlockTime();
    }
    await context.read<AccountViewModel>().reloadAfterUnlock();
    
    setState(() {
      _isAuthenticated = true;
      _showPrivacyOverlay = false;
    });
  }

  void _showPrivacyShield() {
    if (!mounted) return;
    if (!_showPrivacyOverlay) {
      setState(() => _showPrivacyOverlay = true);
    }
  }

  void _dismissPrivacyShield() {
    if (!mounted) return;
    if (_showPrivacyOverlay) {
      setState(() => _showPrivacyOverlay = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!_isInitialized) {
      // Show exact same screen as auth screen during initialization
      // This creates seamless visual continuity
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Same lock icon as auth screen
                  Container(
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
                  const SizedBox(height: 32),
                  
                  // Same title
                  Text(
                    'Authenticator',
                    style: AppTheme.headlineLarge(theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  
                  // Same subtitle as biometric state
                  Text(
                    'Authenticating...',
                    style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget content;

    if (!_authEnabled) {
      content = const HomeScreen();
    } else if (_isAuthenticated) {
      content = const HomeScreen();
    } else {
      content = AuthScreen(
        authService: _authService!,
        onAuthenticated: _onAuthenticated,
      );
    }

    return Stack(
      children: [
        content,
        if (_showPrivacyOverlay)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showPrivacyOverlay ? 1 : 0,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Container(
                        color: theme.colorScheme.surface.withValues(alpha: 0.94),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

