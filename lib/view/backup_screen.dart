import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/theme.dart';
import '../services/backup_service.dart';
import '../view_models/account_view_model.dart';
import '../widgets/backup_password_dialog.dart';
import '../widgets/custom_snackbar.dart';

class BackupScreen extends StatefulWidget {
  final BackupService backupService;

  const BackupScreen({super.key, required this.backupService});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  List<BackupInfo> _backupFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await widget.backupService.listBackupFiles();
      final infos = <BackupInfo>[];

      for (final filePath in files) {
        try {
          final info = await widget.backupService.getBackupInfo(filePath);
          infos.add(info);
        } catch (e) {
          // Skip corrupted or old format files
          if (kDebugMode) {
            debugPrint('Skipping invalid backup file: $filePath - $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _backupFiles = infos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (kDebugMode) {
        debugPrint('Error loading backup files: $e');
      }
    }
  }

  Future<void> _createBackup() async {
    // Show password dialog
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const BackupPasswordDialog(
        title: 'Create Backup',
        description: 'Encrypt your accounts',
        isCreating: true,
      ),
    );

    if (password == null) return;

    // Show progress
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Creating Backup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Encrypting your accounts...',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final filePath = await widget.backupService.createBackup(password);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      // Show success and share options
      await _showBackupSuccess(filePath);

      // Reload backup list
      await _loadBackupFiles();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      CustomSnackbar.show(
        context,
        title: 'Backup Failed',
        message: e.toString().replaceFirst('EncryptionException: ', ''),
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _showBackupSuccess(String filePath) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Text('Backup Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your accounts have been encrypted and saved.'),
            const SizedBox(height: 16),
            Text(
              'Store this backup in a safe location. You\'ll need the password to restore it.',
              style: AppTheme.caption(
                colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('done'),
            child: Text(
              'Done',
              style: AppTheme.bodyMedium(colorScheme.onSurface),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop('share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
            ),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share'),
          ),
        ],
      ),
    );

    if (result == 'share') {
      await Share.shareXFiles([XFile(filePath)], text: 'Authenticator Backup');
    }
  }

  Future<void> _restoreBackup(BackupInfo info) async {
    // Show merge strategy dialog
    final strategy = await _showMergeStrategyDialog();
    if (strategy == null) return;

    // Retry loop for password attempts
    bool success = false;
    int attempts = 0;
    const maxAttempts = 5;

    while (!success && attempts < maxAttempts) {
      attempts++;

      // Show password dialog
      if (!mounted) return;
      final password = await showDialog<String>(
        context: context,
        builder: (context) => BackupPasswordDialog(
          title: 'Restore Backup',
          description: attempts == 1
              ? 'Enter backup password'
              : 'Incorrect password. Try again (${attempts}/$maxAttempts)',
          isCreating: false,
        ),
      );

      if (password == null) return; // User cancelled

      // Show progress
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Restoring Backup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Decrypting and importing accounts...',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      try {
        final result = await widget.backupService.restoreBackup(
          info.filePath,
          password,
          strategy: strategy,
        );

        if (!mounted) return;
        Navigator.of(context).pop(); // Close progress dialog

        // Reload accounts in view model
        final viewModel = context.read<AccountViewModel>();
        await viewModel.reloadAfterUnlock();

        // Force a rebuild to ensure UI updates
        if (mounted) {
          setState(() {});
        }

        // Show success
        CustomSnackbar.show(
          context,
          title: 'Backup Restored',
          message:
              '${result.imported} accounts imported, ${result.skipped} skipped, ${result.replaced} replaced',
          type: SnackbarType.success,
        );

        success = true;

        // Go back to home
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close progress dialog

        final errorMessage = e.toString().replaceFirst(
          'EncryptionException: ',
          '',
        );

        // Check if it's a password error
        if (errorMessage.contains('Incorrect password') ||
            errorMessage.contains('password')) {
          if (attempts >= maxAttempts) {
            // Max attempts reached
            CustomSnackbar.show(
              context,
              title: 'Too Many Attempts',
              message:
                  'Maximum password attempts reached. Please try again later.',
              type: SnackbarType.error,
            );
            return;
          }
          // Continue loop to retry
        } else {
          // Non-password error, show and exit
          CustomSnackbar.show(
            context,
            title: 'Restore Failed',
            message: errorMessage,
            type: SnackbarType.error,
          );
          return;
        }
      }
    }
  }

  Future<MergeStrategy?> _showMergeStrategyDialog() async {
    return showDialog<MergeStrategy>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Duplicate Accounts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How should duplicate accounts be handled?'),
            const SizedBox(height: 16),
            _MergeStrategyOption(
              strategy: MergeStrategy.skip,
              title: 'Skip Duplicates',
              description:
                  'Keep existing accounts, skip duplicates from backup',
              icon: Icons.skip_next,
            ),
            const SizedBox(height: 12),
            _MergeStrategyOption(
              strategy: MergeStrategy.replace,
              title: 'Replace Existing',
              description: 'Replace existing accounts with backup versions',
              icon: Icons.sync,
            ),
            const SizedBox(height: 12),
            _MergeStrategyOption(
              strategy: MergeStrategy.keepBoth,
              title: 'Keep Both',
              description: 'Import duplicates with "(imported)" suffix',
              icon: Icons.content_copy,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.first.path;
      if (filePath == null) return;

      // Get backup info
      final info = await widget.backupService.getBackupInfo(filePath);

      // Restore
      if (!mounted) return;
      await _restoreBackup(info);
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Import Failed',
        message: e.toString(),
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _deleteBackup(BackupInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Backup'),
        content: Text('Delete ${info.fileName}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.backupService.deleteBackup(info.filePath);
      await _loadBackupFiles();

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Backup Deleted',
        message: 'Backup file has been removed',
        type: SnackbarType.info,
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Delete Failed',
        message: e.toString(),
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _exportLatestBackup() async {
    if (_backupFiles.isEmpty) {
      CustomSnackbar.show(
        context,
        title: 'No Backups',
        message: 'Create a backup first before sharing',
        type: SnackbarType.info,
      );
      return;
    }

    // Get latest backup
    final latest = _backupFiles.first;

    // Share the backup file
    try {
      await Share.shareXFiles(
        [XFile(latest.filePath)],
        text:
            'Authenticator Backup - ${latest.createdAt.toString().split('.')[0]}',
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: 'Share Failed',
        message: 'Could not share backup file',
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
          'Backup & Restore',
          style: AppTheme.headlineMedium(colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadBackupFiles,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Encrypted Backup Files',
                                style: AppTheme.bodyLarge(
                                  colorScheme.onSurface,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create password-protected backup files. Works on any device.',
                                style: AppTheme.bodyMedium(
                                  colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createBackup,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Create'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _importBackup,
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            size: 20,
                          ),
                          label: const Text('Import'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exportLatestBackup,
                          icon: const Icon(Icons.share_outlined, size: 20),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Backups list
                  if (_backupFiles.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SAVED BACKUPS',
                          style: AppTheme.caption(colorScheme.onSurface)
                              .copyWith(
                                fontWeight: AppTheme.weightSemiBold,
                                letterSpacing: 1.2,
                              ),
                        ),
                        Text(
                          '${_backupFiles.length} file${_backupFiles.length == 1 ? '' : 's'}',
                          style: AppTheme.caption(
                            colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._backupFiles.map(
                      (info) => _buildBackupCard(info, colorScheme),
                    ),
                  ] else ...[
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Backups Yet',
                            style: AppTheme.bodyLarge(
                              colorScheme.onSurface,
                            ).copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first backup to protect your accounts',
                            style: AppTheme.bodyMedium(
                              colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBackupCard(BackupInfo info, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: InkWell(
        onTap: () => _restoreBackup(info),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_zip_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.fileName,
                      style: AppTheme.bodyMedium(
                        colorScheme.onSurface,
                      ).copyWith(fontWeight: AppTheme.weightSemiBold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${info.fileSizeFormatted} • ${_formatDate(info.createdAt)}',
                      style: AppTheme.caption(
                        colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(
                          Icons.restore,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        const Text('Restore'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(
                          Icons.share,
                          size: 20,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(width: 12),
                        const Text('Share'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'restore':
                      await _restoreBackup(info);
                      break;
                    case 'share':
                      await Share.shareXFiles([XFile(info.filePath)]);
                      break;
                    case 'delete':
                      await _deleteBackup(info);
                      break;
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _MergeStrategyOption extends StatelessWidget {
  final MergeStrategy strategy;
  final String title;
  final String description;
  final IconData icon;

  const _MergeStrategyOption({
    required this.strategy,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => Navigator.of(context).pop(strategy),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.title(
                      colorScheme.onSurface,
                    ).copyWith(fontWeight: AppTheme.weightSemiBold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.caption(
                      colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
