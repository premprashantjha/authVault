import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../app/theme.dart';
import '../app/app_constants.dart';
import '../view_models/account_view_model.dart';
import 'home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _showPrivacyOverlay = false;
  bool _wasInBackground = false;

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
    if (state == AppLifecycleState.paused) {
      _wasInBackground = true;
      _showPrivacyShield();
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      _dismissPrivacyShield();
      
      context.read<AccountViewModel>().purgeSensitiveData();
      
      setState(() {
        _isAuthenticated = false;
      });
      _authenticate();
    } else if (state == AppLifecycleState.inactive) {
      _showPrivacyShield();
    } else if (state == AppLifecycleState.resumed && !_wasInBackground) {
      _dismissPrivacyShield();
    }
  }

  Future<void> _initializeAuth() async {
    await _authenticate();
  }

  Future<void> _authenticate() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics || 
                              await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (mounted) {
          try {
            await context.read<AccountViewModel>().initialize();
          } catch (e) {
            // Initialization error handled silently
          }
          setState(() {
            _isAuthenticated = true;
            _showPrivacyOverlay = false;
          });
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your accounts',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (mounted && authenticated) {
        try {
          await context.read<AccountViewModel>().initialize();
        } catch (e) {
          // Initialization error handled silently
        }
        setState(() {
          _isAuthenticated = true;
          _showPrivacyOverlay = false;
        });
      } else if (mounted && !authenticated) {
        await Future.delayed(AppConstants.authRetryDelay);
        if (mounted) {
          _authenticate();
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          await context.read<AccountViewModel>().initialize();
        } catch (reloadError) {
          // Initialization error handled silently
        }
        setState(() {
          _isAuthenticated = true;
          _showPrivacyOverlay = false;
        });
      }
    }
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
    
    if (!_isAuthenticated) {
      return _buildAuthenticationScreen(theme);
    }
    
    return Stack(
      children: [
        Consumer<AccountViewModel>(
          builder: (context, viewModel, _) {
            return HomeScreen(key: ValueKey(viewModel.accounts.length));
          },
        ),
        if (_showPrivacyOverlay) _buildPrivacyOverlay(theme),
      ],
    );
  }

  Widget _buildAuthenticationScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Watermark logo at bottom
          Positioned(
            bottom: AppConstants.spaceXl + AppConstants.spaceSm,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: AppConstants.opacityWatermark,
                child: Image.asset(
                  'assets/images/CDAC_Logo.png',
                  width: AppConstants.spaceXxl * 4,
                  height: AppConstants.spaceXxl * 4,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          // Authentication content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo
                Image.asset(
                  'assets/images/Logo1.png',
                  height: AppConstants.iconSizeXxl + AppConstants.spaceXl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.lock_outline,
                      size: AppConstants.iconSizeXxl * 2,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    );
                  },
                ),
                SizedBox(height: AppConstants.spaceLg),
                // Status text
                Text(
                  'Authenticating...',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeTitle,
                    fontWeight: AppTheme.weightMedium,
                    color: theme.colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium),
                  ),
                ),
                SizedBox(height: AppConstants.spaceMd),
                // Loading indicator
                SizedBox(
                  width: AppConstants.iconSizeXl,
                  height: AppConstants.iconSizeXl,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOverlay(ThemeData theme) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedOpacity(
          duration: AppConstants.durationFast,
          opacity: _showPrivacyOverlay ? 1 : 0,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: Stack(
              children: [
                Positioned(
                  bottom: AppConstants.spaceXl + AppConstants.spaceSm,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Opacity(
                      opacity: AppConstants.opacityWatermark,
                      child: Image.asset(
                        'assets/images/CDAC_Logo.png',
                        width: AppConstants.spaceXxl * 4,
                        height: AppConstants.spaceXxl * 4,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/Logo1.png',
                        height: AppConstants.iconSizeXxl + AppConstants.spaceXl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.lock_outline,
                            size: AppConstants.iconSizeXxl * 2,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
                          );
                        },
                      ),
                      SizedBox(height: AppConstants.spaceLg),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

