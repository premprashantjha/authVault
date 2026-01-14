import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Dialog to prompt user to restore from backup
/// 
/// Shows when backup is detected on app launch
/// Gives user choice to restore now or later
class RestorePromptDialog extends StatelessWidget {
  final int accountCount;
  
  const RestorePromptDialog({
    super.key,
    required this.accountCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.backup,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Restore Your Accounts?',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'We found a backup from your previous installation.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What will be restored:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRestoreItem(
                  context,
                  '$accountCount ${accountCount == 1 ? 'account' : 'accounts'}',
                ),
                _buildRestoreItem(context, 'Favorites'),
                _buildRestoreItem(context, 'Settings'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You can also restore later from Settings.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not Now'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Restore'),
        ),
      ],
    );
  }

  Widget _buildRestoreItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Show restore prompt dialog
/// 
/// Returns true if user wants to restore, false if not
Future<bool?> showRestorePromptDialog(
  BuildContext context, {
  required int accountCount,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false, // Must choose
    builder: (context) => RestorePromptDialog(
      accountCount: accountCount,
    ),
  );
}
