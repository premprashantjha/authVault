import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../app/app_constants.dart';
import '../services/local_backup_service.dart';
import '../view_models/account_view_model.dart';
import '../widgets/restore_prompt_dialog.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/backup_password_dialog.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final List<String> tips;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.tips,
  });
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final bool allowSkip;
  final bool isReviewMode;
  final int initialPageIndex;
  final VoidCallback? onSetupPin;
  final VoidCallback? onEnableBiometrics;
  final VoidCallback? onOpenDiagnostics;
  final VoidCallback? onEnablePassphrase;
  final bool hasBackupAvailable;

  const OnboardingScreen({
    super.key,
    required this.onFinished,
    this.allowSkip = true,
    this.isReviewMode = false,
    this.initialPageIndex = 0,
    this.onSetupPin,
    this.onEnableBiometrics,
    this.onOpenDiagnostics,
    this.onEnablePassphrase,
    this.hasBackupAvailable = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  late final int _initialPage;
  int _currentIndex = 0;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Your Data Stays Local',
      description: 'All your accounts are encrypted and stored securely on your device only.',
      icon: Icons.security,
      tips: [
        'No cloud sync or data collection',
        'Strong encryption protects your secrets',
        'Only you have access to your data',
      ],
    ),
    OnboardingSlide(
      title: 'Device Security',
      description: 'Your device lock (PIN/pattern/biometric) protects access to the app.',
      icon: Icons.lock_outline,
      tips: [
        'Uses your existing device security',
        'No separate app password needed',
        'Automatically locks when you leave the app',
      ],
    ),
    OnboardingSlide(
      title: 'Keep Devices Secure',
      description: 'We protect your data with built-in security features.',
      icon: Icons.phonelink_lock,
      tips: [
        'Screenshots are blocked for privacy',
        'Warns if device security is compromised',
        'Screen content is hidden when app is in background',
      ],
    ),
    OnboardingSlide(
      title: 'Backup Your Accounts',
      description: 'Create encrypted backups to protect against device loss or damage.',
      icon: Icons.backup,
      tips: [
        'Backups are encrypted with your password',
        'Store backups in a safe location',
        'Test your backup by restoring on another device',
        'Keep backup passwords secure and memorable',
      ],
    ),
    OnboardingSlide(
      title: 'You\'re All Set!',
      description: 'Your authenticator is ready to use. Add accounts and stay secure.',
      icon: Icons.verified_user,
      tips: [
        'Tap + to add your first account',
        'Scan QR codes or enter keys manually',
        'Create regular backups of your accounts',
        'Review this guide anytime from Settings',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initialPage = widget.initialPageIndex.clamp(0, _slides.length - 1);
    _currentIndex = _initialPage;
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() async {
    if (_currentIndex == _slides.length - 1) {
      // On last page, check if backup is available
      if (widget.hasBackupAvailable && !widget.isReviewMode) {
        await _handleRestorePrompt();
      } else {
        widget.onFinished();
      }
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goPrevious() {
    if (_currentIndex == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  /// Handle restore prompt on last onboarding page
  Future<void> _handleRestorePrompt() async {
    if (!mounted) return;
    
    try {
      // Check which type of backup is available
      if (widget.hasBackupAvailable) {
        // Local backup available - show local restore option
        await _handleLocalRestore();
      }
      
      // Continue to app (whether restored or not)
      widget.onFinished();
    } catch (e) {
      // If anything fails, just continue to app
      widget.onFinished();
    }
  }
  
  /// Handle local backup restore
  Future<void> _handleLocalRestore() async {
    if (!mounted) return;
    
    try {
      // Get backup info to show in dialog
      final accountViewModel = context.read<AccountViewModel>();
      final localBackupService = LocalBackupService(
        accountService: accountViewModel.accountService,
      );
      
      final accountCount = await _getBackupAccountCount(localBackupService);
      
      final shouldRestore = await showRestorePromptDialog(
        context,
        accountCount: accountCount,
      );
      
      if (shouldRestore == true) {
        await _performRestore(localBackupService);
      }
    } catch (e) {
    }
  }

  Future<int> _getBackupAccountCount(LocalBackupService backupService) async {
    try {
      final metadata = await backupService.getBackupMetadata();
      return metadata?['account_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _performRestore(LocalBackupService backupService) async {
    if (!mounted) return;
    
    // Prompt for password
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const BackupPasswordDialog(
        title: 'Restore Backup',
        description: 'Enter your backup password',
        isCreating: false,
      ),
    );
    
    if (password == null || !mounted) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Restoring your accounts...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    try {
      // Restore backup with password
      final restored = await backupService.restoreAutoBackup(password);
      
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show result
      if (mounted) {
        if (restored) {
          CustomSnackbar.show(
            context,
            message: 'Accounts restored successfully!',
            type: SnackbarType.success,
          );
        } else {
          CustomSnackbar.show(
            context,
            message: 'Restore failed. You can try again from Settings.',
            type: SnackbarType.error,
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show error
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Restore failed: ${e.toString()}',
          type: SnackbarType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentIndex == _slides.length - 1;
    final skipLabel = widget.isReviewMode ? 'Close' : 'Skip';
    final completionLabel = widget.isReviewMode ? 'Close' : 'Get Started';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.getResponsivePadding(context).left,
                vertical: AppConstants.getResponsiveSpacing(context),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.allowSkip || widget.isReviewMode)
                    TextButton(
                      onPressed: widget.onFinished,
                      child: Text(
                        skipLabel,
                        style: AppTheme.responsiveBodyMedium(context, theme.colorScheme.primary),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.getResponsivePadding(context).left,
                      vertical: AppConstants.getResponsiveSpacing(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: AppConstants.getResponsiveSpacing(context)),
                        Container(
                          height: AppConstants.getResponsiveIconSize(context, small: 64.0, medium: 72.0, large: 80.0),
                          width: AppConstants.getResponsiveIconSize(context, small: 64.0, medium: 72.0, large: 80.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppConstants.getResponsiveRadius(context, large: 24.0)),
                          ),
                          child: Icon(
                            slide.icon, 
                            size: AppConstants.getResponsiveIconSize(context, small: 32.0, medium: 40.0, large: 48.0), 
                            color: theme.colorScheme.primary
                          ),
                        ),
                        SizedBox(height: AppConstants.getResponsiveSpacing(context, lg: 32.0, xl: 40.0)),
                        Text(
                          slide.title,
                          style: AppTheme.responsiveHeadlineMedium(context, theme.colorScheme.onSurface).copyWith(
                            fontWeight: AppTheme.weightBold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...slide.tips.map(
                          (tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  alignment: Alignment.topLeft,
                                  child: Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 32 : 10,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentIndex == 0 ? null : _goPrevious,
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _goNext,
                          child: Text(isLast ? completionLabel : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
