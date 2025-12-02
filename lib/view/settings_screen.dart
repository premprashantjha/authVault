import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/encryption_service.dart';
import '../services/integrity_service.dart';
import '../services/database_service.dart';
import '../services/account_service.dart';
import '../widgets/animated_button.dart';
import '../widgets/skeleton.dart';
import '../widgets/custom_snackbar.dart';
import 'onboarding_screen.dart';
import 'backup_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService authService;

  const SettingsScreen({
    super.key,
    required this.authService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _authEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricToggleLoading = false;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _openSecurityGuide({int initialPage = 0}) {
    final navigator = Navigator.of(context);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => OnboardingScreen(
          allowSkip: false,
          isReviewMode: true,
          initialPageIndex: initialPage,
          onFinished: () {
            navigator.pop();
          },
        ),
      ),
    );
  }

  // Lightweight skeletons for settings loading state
  Widget _buildLoadingSkeletons() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Security header + few skeleton cards
        const SizedBox(height: 4),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        // Skeleton cards
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: const [
              // mimic setting card
              SizedBox(height: 16),
              SizedBox(height: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 8),
        // Reuse Skeleton widgets that approximate card height
        const Skeleton(height: 64),
        const SizedBox(height: 12),
        const Skeleton(height: 64),
        const SizedBox(height: 12),
        const Skeleton(height: 64),
        const SizedBox(height: 24),

        // Appearance section skeletons
        const Skeleton(height: 64),
        const SizedBox(height: 24),

        // Backup & About skeletons
        const Skeleton(height: 64),
        const SizedBox(height: 24),
        const Skeleton(height: 64),
      ],
    );
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      // Validate auth state first (handles edge cases)
      await widget.authService.validateAuthState();

      // Gather all state in parallel where possible
      final authEnabled = await widget.authService.isAuthEnabled();
      final biometricAvailable = await widget.authService.isBiometricAvailable();
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabledPref = prefs.getBool('authenticator_biometric_enabled') ?? false;
      final hasPin = await widget.authService.hasPin();

      // Check if biometric is still available if enabled and auth is enabled
      bool actualBiometricEnabled = false;
      if (biometricEnabledPref && authEnabled) {
        final stillAvailable = await widget.authService.isBiometricStillAvailable();
        actualBiometricEnabled = stillAvailable;
      }

      if (mounted) {
        // Batch update all settings at once to avoid intermediate flicker
        setState(() {
          _authEnabled = authEnabled;
          _biometricAvailable = biometricAvailable;
          _biometricEnabled = actualBiometricEnabled;
          _hasPin = hasPin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleAuthentication(bool enabled) async {
    if (enabled) {
      // Show PIN setup dialog (Add mode when enabling auth)
      final result = await _showPinSetupDialog(isAddMode: true);
      if (!mounted) return;
      if (result != null && result) {
        setState(() => _authEnabled = true);
        _loadSettings(); // Reload to update UI
      }
    } else {
      // Disable authentication
      final confirmed = await _showDisableAuthDialog();
      if (confirmed == true) {
        await widget.authService.disableAuth();
        if (mounted) {
          setState(() {
            _authEnabled = false;
            _biometricEnabled = false;
          });
          CustomSnackbar.show(
            context,
            title: 'Authentication Disabled',
            message: 'App lock has been turned off. Anyone with this device can open Authenticator.',
            type: SnackbarType.error,
          );
        }
      }
    }
  }

  Future<void> _showAddPinDialog() async {
    final result = await _showPinSetupDialog(isAddMode: true);
    if (result == true && mounted) {
      _loadSettings(); // Reload to update UI
    }
  }

  Future<bool?> _showPinSetupDialog({bool isAddMode = false}) async {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isAddMode ? 'Add PIN' : 'Set Up PIN',
            style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                  cursorColor: theme.colorScheme.onSurface,
                  decoration: InputDecoration(
                    labelText: 'Enter 6-digit PIN',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a PIN';
                    }
                    if (value.length != 6) {
                      return 'PIN must be exactly 6 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                  cursorColor: theme.colorScheme.onSurface,
                  decoration: InputDecoration(
                    labelText: 'Confirm PIN',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) {
                    if (value != pinController.text) {
                      return 'PINs do not match';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
            ),
            AnimatedButton(
              onTap: () async {
                if (formKey.currentState!.validate()) {
                  final dialogNavigator = Navigator.of(context);
                  final success = await widget.authService.enablePinAuth(pinController.text);
                  if (!mounted) return;
                  dialogNavigator.pop(success);
                  if (success) {
                    CustomSnackbar.show(
                      context,
                      title: 'Success',
                      message: isAddMode ? 'PIN has been added successfully' : 'PIN has been set successfully',
                      type: SnackbarType.success,
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  isAddMode ? 'Add PIN' : 'Set PIN',
                  style: AppTheme.bodyMedium(theme.colorScheme.onPrimary).copyWith(
                    fontWeight: AppTheme.weightSemiBold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDisableAuthDialog() async {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Disable Authentication',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to disable app authentication? Your app will be accessible without a PIN or biometric.',
          style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Disable', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      // Check if PIN exists first
      final hasPin = await widget.authService.hasPin();
      if (!hasPin) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            title: 'PIN Required',
            message: 'Please set up a PIN first as a fallback option',
            type: SnackbarType.warning,
          );
        }
        // Reset toggle
        if (mounted) {
          setState(() => _biometricEnabled = false);
        }
        return;
      }
      
      // Show loading while native biometric prompt and enable flow run
      if (mounted) setState(() => _biometricToggleLoading = true);
      try {
        final success = await widget.authService.enableBiometricAuth();
        if (mounted) {
          setState(() {
            _biometricEnabled = success;
            _biometricToggleLoading = false;
          });
          if (success) {
            CustomSnackbar.show(
              context,
              title: 'Success',
              message: 'Biometric authentication has been enabled',
              type: SnackbarType.success,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _biometricEnabled = false;
            _biometricToggleLoading = false;
          });
          CustomSnackbar.show(
            context,
            title: 'Error',
            message: e.toString().replaceFirst('Exception: ', ''),
            type: SnackbarType.error,
          );
        }
      }
    } else {
      // Disable biometric (but keep PIN if enabled)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('authenticator_biometric_enabled', false);
      if (mounted) {
        setState(() => _biometricEnabled = false);
        CustomSnackbar.show(
          context,
          title: 'Biometric Disabled',
          message: 'Face/Touch unlock is off until you re-enable it.',
          type: SnackbarType.error,
        );
      }
    }
  }

  // Some dialog flows intentionally capture Theme/ScaffoldMessenger/Navigator
  // before awaiting asynchronous auth calls. The mounted checks and captured
  // objects ensure safety; suppress the analyzer warning for this function.
  // ignore: use_build_context_synchronously
  Future<void> _showChangePinDialog() async {
    final theme = Theme.of(context);
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // First, verify current PIN
    final verified = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Verify Current PIN',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: oldPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            cursorColor: theme.colorScheme.onSurface,
            decoration: InputDecoration(
              labelText: 'Enter current PIN',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your current PIN';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
          AnimatedButton(
            onTap: () async {
              if (formKey.currentState!.validate()) {
                final dialogNavigator = Navigator.of(context);
                final isValid = await widget.authService.authenticateWithPin(oldPinController.text);
                if (!mounted) return;
                dialogNavigator.pop(isValid);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Verify',
                style: AppTheme.bodyMedium(theme.colorScheme.onPrimary).copyWith(
                  fontWeight: AppTheme.weightSemiBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

      if (verified != true) {
      if (!mounted) return;
      if (verified == false) {
        CustomSnackbar.show(
          context,
          title: 'Invalid PIN',
          message: 'The PIN you entered is incorrect',
          type: SnackbarType.error,
        );
      }
      return;
    }

    // Now show change PIN dialog
    final formKey2 = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Change PIN',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        content: Form(
          key: formKey2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: newPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                maxLength: 6,
                style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                cursorColor: theme.colorScheme.onSurface,
                decoration: InputDecoration(
                  labelText: 'Enter new 6-digit PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new PIN';
                  }
                  if (value.length != 6) {
                    return 'PIN must be exactly 6 digits';
                  }
                  if (value == oldPinController.text) {
                    return 'New PIN must be different from current PIN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                cursorColor: theme.colorScheme.onSurface,
                decoration: InputDecoration(
                  labelText: 'Confirm new PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value != newPinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
          AnimatedButton(
            onTap: () async {
              if (formKey2.currentState!.validate()) {
                final dialogNavigator = Navigator.of(context);
                final success = await widget.authService.enablePinAuth(newPinController.text);
                if (!mounted) return;
                dialogNavigator.pop(success);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Change PIN',
                style: AppTheme.bodyMedium(theme.colorScheme.onPrimary).copyWith(
                  fontWeight: AppTheme.weightSemiBold,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == true) {
      CustomSnackbar.show(
        context,
        title: 'Success',
        message: 'Your PIN has been changed successfully',
        type: SnackbarType.success,
      );
    } else if (result == false) {
      CustomSnackbar.show(
        context,
        title: 'Error',
        message: 'Failed to change PIN. Please try again',
        type: SnackbarType.error,
      );
    }
  }

  void _navigateToBackup(BuildContext context) {
    // Create backup service with dependencies
    final encryptionService = EncryptionService();
    final integrityService = IntegrityService();
    final databaseService = DatabaseService(
      encryptionService: encryptionService,
      integrityService: integrityService,
    );
    final accountService = AccountService(databaseService: databaseService);
    final backupService = BackupService(accountService: accountService);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BackupScreen(backupService: backupService),
      ),
    );
  }

  void _navigateToPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Future<void> _showRemovePinDialog() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove PIN',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        content: Text(
          'Removing your PIN will also disable biometric authentication. The app will open without any lock. Do you want to continue?',
          style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Remove PIN', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final success = await widget.authService.removePin();
        if (!mounted) return;
        if (success) {
          setState(() {
            _authEnabled = false;
            _biometricEnabled = false;
          });
          CustomSnackbar.show(
            context,
            title: 'PIN Removed',
            message: 'App lock and biometrics are now off for this device.',
            type: SnackbarType.error,
          );
          // Reload settings to update UI
          _loadSettings();
        }
      } catch (e) {
        if (!mounted) return;
        CustomSnackbar.show(
          context,
          title: 'Error',
          message: e.toString().replaceFirst('Exception: ', ''),
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? _buildLoadingSkeletons()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Security Section
                _buildSectionHeader('Security', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.lock_outline,
                  title: 'App Authentication',
                  subtitle: _authEnabled
                      ? 'PIN or Biometric required'
                      : 'No authentication required',
                  trailing: Switch(
                    value: _authEnabled,
                    onChanged: _toggleAuthentication,
                  ),
                ),
                const SizedBox(height: 12),
                if (_authEnabled) ...[
                  // PIN Management
                  const SizedBox(height: 12),
                  // Use preloaded _hasPin state to avoid flicker from async FutureBuilder
                  if (_hasPin) ...[
                    _buildSettingCard(
                      context,
                      icon: Icons.lock,
                      title: 'Change PIN',
                      subtitle: 'Update your PIN code',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      onTap: () => _showChangePinDialog(),
                    ),
                    if (_biometricEnabled) ...[
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        context,
                        icon: Icons.lock_open,
                        title: 'Remove PIN',
                        subtitle: 'Removes PIN and biometric (no app lock)',
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        onTap: () => _showRemovePinDialog(),
                      ),
                    ],
                  ] else ...[
                    // No PIN - show Add PIN option
                    _buildSettingCard(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Add PIN',
                      subtitle: 'Set up a PIN code for authentication',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      onTap: () => _showAddPinDialog(),
                    ),
                  ],
                  
                  // Biometric Authentication (only show if available)
                  if (_biometricAvailable) ...[
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      icon: Icons.fingerprint,
                      title: _biometricEnabled ? 'Biometric Authentication' : 'Add Biometric',
                      subtitle: _biometricEnabled
                          ? 'Use fingerprint or face ID'
                          : 'Enable fingerprint or face ID authentication\n(PIN required as fallback)',
                      trailing: _biometricToggleLoading
                          ? SizedBox(
                              width: 48,
                              height: 24,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                  ),
                                ),
                              ),
                            )
                          : Switch(
                              value: _biometricEnabled,
                              onChanged: _toggleBiometric,
                            ),
                    ),
                  ] else ...[
                    // Show message if biometric not available
                    const SizedBox(height: 12),
                    _buildSettingCard(
                      context,
                      icon: Icons.info_outline,
                      title: 'Biometric Authentication',
                      subtitle: 'Not available on this device',
                      trailing: Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onTap: null,
                    ),
                  ],
                ],
                const SizedBox(height: 24),

                // Appearance Section - Removed theme toggle to keep native/Flutter splash in sync
                // App always follows system theme for professional, seamless experience
                _buildSectionHeader('Appearance', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.brightness_auto,
                  title: 'Theme',
                  subtitle: 'Follows system theme (Light/Dark)',
                  trailing: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  onTap: null,
                ),
                const SizedBox(height: 24),

                // Backup & Recovery Section
                _buildSectionHeader('Data Management', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.backup,
                  title: 'Backup & Restore',
                  subtitle: 'Encrypted backups of your accounts',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToBackup(context),
                ),
                const SizedBox(height: 24),

                // Guides & Reference Section
                _buildSectionHeader('Guides & Reference', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'Review Security Guide',
                  subtitle: 'Walk through onboarding tips again',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _openSecurityGuide(),
                ),
                const SizedBox(height: 24),

                // Legal Section
                _buildSectionHeader('Legal', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we protect your data',
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onTap: () => _navigateToPrivacyPolicy(context),
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSectionHeader('About', theme),
                const SizedBox(height: 8),
                _buildSettingCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: '1.0.0',
                  trailing: const SizedBox.shrink(),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title.toUpperCase(),
      style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: AppTheme.caption(theme.colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
