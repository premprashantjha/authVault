import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../app/theme.dart';
import '../services/backup_service.dart';
import '../view_models/account_view_model.dart';
import '../widgets/backup_password_dialog.dart';
import '../widgets/custom_snackbar.dart';
import '../widgets/animated_button.dart';

class BackupScreen extends StatefulWidget {
  final BackupService backupService;

  const BackupScreen({
    super.key,
    required this.backupService,
  });

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
          // Skip corrupted files
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
    
    // Show progress with better UI
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
        message: e.toString().replaceFirst('BackupException: ', ''),
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _showBackupSuccess(String filePath) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary),
            const SizedBox(width: 12),
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
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('done'),
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop('share'),
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
      
      // Show progress with better UI
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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
        await context.read<AccountViewModel>().reloadAfterUnlock();
        
        // Show success
        CustomSnackbar.show(
          context,
          title: 'Backup Restored',
          message: '${result.imported} accounts imported, ${result.skipped} skipped, ${result.replaced} replaced',
          type: SnackbarType.success,
        );
        
        success = true;
        
        // Go back to home
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close progress dialog
        
        final errorMessage = e.toString().replaceFirst('BackupException: ', '');
        
        // Check if it's a password error
        if (errorMessage.contains('Incorrect password') || 
            errorMessage.contains('password')) {
          
          if (attempts >= maxAttempts) {
            // Max attempts reached
            CustomSnackbar.show(
              context,
              title: 'Too Many Attempts',
              message: 'Maximum password attempts reached. Please try again later.',
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
              description: 'Keep existing accounts, skip duplicates from backup',
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
        type: FileType.any, // Changed from custom to any for better compatibility
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Backup & Restore'),
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: AnimatedButton(
                        onTap: _createBackup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.backup, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Create Backup',
                                style: AppTheme.bodyMedium(Colors.white).copyWith(
                                  fontWeight: AppTheme.weightSemiBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedButton(
                        onTap: _importBackup,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.file_upload, color: colorScheme.onSecondaryContainer, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Import Backup',
                                style: AppTheme.bodyMedium(colorScheme.onSecondaryContainer).copyWith(
                                  fontWeight: AppTheme.weightSemiBold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Backup files list
                Text(
                  'Local Backups',
                  style: AppTheme.headlineMedium(colorScheme.onSurface),
                ),
                const SizedBox(height: 12),
                
                if (_backupFiles.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.folder_open,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No backups found',
                            style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(_backupFiles.length, (index) {
                    final info = _backupFiles[index];
                    return _BackupFileCard(
                      info: info,
                      onRestore: () => _restoreBackup(info),
                      onDelete: () => _deleteBackup(info),
                      onShare: () async {
                        await Share.shareXFiles([XFile(info.filePath)]);
                      },
                    );
                  }),
              ],
            ),
    );
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.bodyMedium(colorScheme.onSurface).copyWith(
                      fontWeight: AppTheme.weightSemiBold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
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

class _BackupFileCard extends StatelessWidget {
  final BackupInfo info;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _BackupFileCard({
    required this.info,
    required this.onRestore,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.folder_zip, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(info.createdAt),
                        style: AppTheme.bodyMedium(colorScheme.onSurface).copyWith(
                          fontWeight: AppTheme.weightSemiBold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.fileSizeFormatted,
                        style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Restore'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 20),
                  tooltip: 'Share',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 20, color: colorScheme.error),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
