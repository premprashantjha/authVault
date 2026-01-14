import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  bool _showLockedScreen = false; // New: Show locked screen instead of infinite retry

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
      
      // Purge sensitive data (OTP codes) but keep account list
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
        // No biometric available - allow access (device has no security)
        if (mounted) {
          try {
            await context.read<AccountViewModel>().initialize();
          } catch (e) {
            // Initialization error handled silently
          }
          setState(() {
            _isAuthenticated = true;
            _showPrivacyOverlay = false;
            _showLockedScreen = false;
          });
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your accounts',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows fallback to device PIN/password
          useErrorDialogs: true,
        ),
      );

      if (mounted && authenticated) {
        // ✅ Authentication successful
        try {
          await context.read<AccountViewModel>().initialize();
        } catch (e) {
          // Initialization error handled silently
        }
        
        setState(() {
          _isAuthenticated = true;
          _showPrivacyOverlay = false;
          _showLockedScreen = false;
        });
      } else if (mounted && !authenticated) {
        // ❌ Authentication failed or cancelled
        // Show locked screen instead of infinite retry
        setState(() {
          _showLockedScreen = true;
        });
      }
    } catch (e) {
      // ❌ Error occurred (including user cancel)
      // Show locked screen instead of infinite retry
      if (mounted) {
        setState(() {
          _showLockedScreen = true;
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
      // Show locked screen if user cancelled, otherwise show loading
      return _showLockedScreen 
          ? _buildLockedScreen(theme)
          : _buildAuthenticationScreen(theme);
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
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    theme.brightness == Brightness.dark
                        ? theme.colorScheme.primary // Use theme primary color
                        : Colors.transparent,
                    theme.brightness == Brightness.dark
                        ? BlendMode.srcATop
                        : BlendMode.dst,
                  ),
                  child: Image.asset(
                    'assets/images/Logo_cdac.png',
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

  Widget _buildLockedScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spaceXl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon with CDAC watermark behind it
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // CDAC logo watermark behind lock icon - increased opacity
                    Opacity(
                      opacity: 0.15,
                      child: Image.asset(
                        'assets/images/CDAC_Logo.png',
                        width: AppConstants.iconSizeXxl * 3.5,
                        height: AppConstants.iconSizeXxl * 3.5,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                    // Lock icon with circular background
                    Container(
                      padding: EdgeInsets.all(AppConstants.spaceLg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_outline,
                        size: AppConstants.iconSizeXxl * 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppConstants.spaceLg),
                // Locked text
                Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeTitle,
                    fontWeight: AppTheme.weightBold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: AppConstants.spaceSm),
                // Subtitle
                Text(
                  'Authenticate to access your accounts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeBody,
                    color: theme.colorScheme.onSurface.withValues(alpha: AppConstants.opacityMedium),
                  ),
                ),
                SizedBox(height: AppConstants.spaceXl * 1.5),
                // Unlock button - improved design
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight + 8,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showLockedScreen = false;
                      });
                      _authenticate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: AppConstants.elevationMedium,
                      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: AppConstants.iconSizeLg + 4,
                        ),
                        SizedBox(width: AppConstants.spaceSm),
                        Text(
                          'Unlock',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody + 2,
                            fontWeight: AppTheme.weightSemiBold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                      ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          theme.brightness == Brightness.dark
                              ? theme.colorScheme.primary // Use theme primary color
                              : Colors.transparent,
                          theme.brightness == Brightness.dark
                              ? BlendMode.srcATop
                              : BlendMode.dst,
                        ),
                        child: Image.asset(
                          'assets/images/Logo_cdac.png',
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

