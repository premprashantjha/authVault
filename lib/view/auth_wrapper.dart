import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
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
    if (_authService == null || !_authEnabled) return;
    
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - check if should re-lock
      _checkAndRelock();
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.inactive) {
      // App went to background - no action needed
      // Will check timeout when app resumes
    }
  }

  Future<void> _checkAndRelock() async {
    if (_authService == null || !_authEnabled) return;
    
    final shouldRelock = await _authService!.shouldRelock();
    if (shouldRelock && mounted) {
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
    
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If auth is not enabled, show home screen directly
    if (!_authEnabled) {
      return const HomeScreen();
    }

    // If authenticated, show home screen
    if (_isAuthenticated) {
      return const HomeScreen();
    }

    // Show auth screen
    return AuthScreen(
      authService: _authService!,
      onAuthenticated: _onAuthenticated,
    );
  }
}

