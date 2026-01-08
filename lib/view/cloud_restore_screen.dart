import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/cloud_sync_service.dart';
import '../widgets/custom_snackbar.dart';

/// Screen for restoring accounts from cloud backup
class CloudRestoreScreen extends StatefulWidget {
  final CloudSyncService cloudSyncService;
  final VoidCallback? onRestoreComplete;

  const CloudRestoreScreen({
    super.key,
    required this.cloudSyncService,
    this.onRestoreComplete,
  });

  @override
  State<CloudRestoreScreen> createState() => _CloudRestoreScreenState();
}

class _CloudRestoreScreenState extends State<CloudRestoreScreen> {
  final _passwordController = TextEditingController();
  bool _isRestoring = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRestore() async {
    if (_passwordController.text.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Please enter your backup password',
        type: SnackbarType.error,
      );
      return;
    }

    setState(() => _isRestoring = true);

    try {
      final accountsRestored = await widget.cloudSyncService.restoreFromCloud(
        _passwordController.text,
      );

      if (!mounted) return;

      CustomSnackbar.show(
        context,
        title: 'Restore Complete',
        message: 'Successfully restored $accountsRestored accounts',
        type: SnackbarType.success,
      );

      // Call completion callback
      widget.onRestoreComplete?.call();

      // Navigate back
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isRestoring = false);

      CustomSnackbar.show(
        context,
        title: 'Restore Failed',
        message: e.toString().replaceFirst('CloudSyncException: ', ''),
        type: SnackbarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Restore from Cloud',
          style: AppTheme.headlineMedium(colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_download_rounded,
                size: 50,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Restore Your Accounts',
              style: AppTheme.headlineLarge(colorScheme.onSurface).copyWith(
                fontWeight: AppTheme.weightBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              'Enter your backup password to restore your accounts from cloud storage',
              style: AppTheme.bodyMedium(
                colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Password field
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isRestoring,
              style: AppTheme.bodyMedium(colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Backup Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _handleRestore(),
            ),
            const SizedBox(height: 32),

            // Restore button
            ElevatedButton(
              onPressed: _isRestoring ? null : _handleRestore,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRestoring
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Restore Accounts'),
            ),
            const SizedBox(height: 16),

            // Skip button
            TextButton(
              onPressed: _isRestoring ? null : () => Navigator.of(context).pop(),
              child: const Text('Skip for Now'),
            ),
            const SizedBox(height: 32),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is the same password you used when you enabled cloud backup. '
                      'If you forgot it, your backup cannot be recovered.',
                      style: AppTheme.caption(
                        colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
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
