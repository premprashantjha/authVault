import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../services/backup_encryption_service.dart';

/// Dialog for entering backup password with strength indicator
class BackupPasswordDialog extends StatefulWidget {
  final String title;
  final String description;
  final bool isCreating; // true for backup, false for restore

  const BackupPasswordDialog({
    super.key,
    required this.title,
    required this.description,
    this.isCreating = true,
  });

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _encryptionService = BackupEncryptionService();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _onPasswordChanged(String value) {
    setState(() {
      _passwordStrength = _encryptionService.estimatePasswordStrength(value);
      _passwordError = null;
    });
  }

  void _onConfirm() {
    final password = _passwordController.text;
    
    // Basic validation (just minimum requirements)
    final error = _encryptionService.validatePassword(password);
    if (error != null) {
      setState(() => _passwordError = error);
      HapticFeedback.heavyImpact();
      return;
    }
    
    // Check confirmation match (only for backup creation)
    if (widget.isCreating && password != _confirmController.text) {
      setState(() => _passwordError = 'Passwords do not match');
      HapticFeedback.heavyImpact();
      return;
    }
    
    // Check for warnings (non-blocking)
    final warning = _encryptionService.getPasswordWarning(password);
    if (warning != null && widget.isCreating) {
      // Show warning dialog but let user proceed
      _showPasswordWarningDialog(password, warning);
      return;
    }
    
    // Return password
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(password);
  }
  
  Future<void> _showPasswordWarningDialog(String password, String warning) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text('Weak Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(warning),
              const SizedBox(height: 16),
              Text(
                'You can still use this password, but a stronger one is recommended for better security.',
                style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Change Password'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
              ),
              child: const Text('Use Anyway'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      // User chose to proceed with weak password
      HapticFeedback.lightImpact();
      if (mounted) {
        Navigator.of(context).pop(password);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRetry = widget.description.contains('Incorrect') || widget.description.contains('Try again');
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Retry warning banner
              if (isRetry) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Previous password was incorrect. Please try a different password.',
                          style: AppTheme.caption(colorScheme.onSurface).copyWith(
                            fontWeight: AppTheme.weightMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isCreating ? Icons.lock_outline : Icons.lock_open,
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
                          widget.title,
                          style: AppTheme.headlineMedium(colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRetry ? 'Enter backup password' : widget.description,
                          style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofocus: true,
                style: AppTheme.bodyMedium(colorScheme.onSurface),
                cursorColor: colorScheme.primary,
                onChanged: _onPasswordChanged,
                onSubmitted: (_) => widget.isCreating ? null : _onConfirm(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                  hintText: 'Enter a strong password',
                  hintStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.5)),
                  prefixIcon: Icon(Icons.lock, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colorScheme.primary, width: 2),
                  ),
                ),
              ),
              
              // Password strength indicator (only for backup creation)
              if (widget.isCreating && _passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 12),
                _PasswordStrengthIndicator(strength: _passwordStrength),
              ],
              
              // Confirm password field (only for backup creation)
              if (widget.isCreating) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: AppTheme.bodyMedium(colorScheme.onSurface),
                  cursorColor: colorScheme.primary,
                  onSubmitted: (_) => _onConfirm(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                    hintText: 'Re-enter password',
                    hintStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.5)),
                    prefixIcon: Icon(Icons.lock, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                ),
              ],
              
              // Error message
              if (_passwordError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _passwordError!,
                          style: AppTheme.caption(colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Security notice
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isCreating
                            ? 'This password encrypts your backup. Store it securely - it cannot be recovered if lost.'
                            : 'Enter the password you used to create this backup.',
                        style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel', style: AppTheme.bodyMedium(colorScheme.onSurface)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.isCreating ? 'Create Backup' : 'Restore',
                        style: AppTheme.bodyMedium(colorScheme.onPrimary).copyWith(
                          fontWeight: AppTheme.weightSemiBold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Password strength indicator widget
class _PasswordStrengthIndicator extends StatelessWidget {
  final int strength; // 0-100

  const _PasswordStrengthIndicator({required this.strength});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Determine strength color and text based on score
    Color strengthColor = colorScheme.tertiary;
    String strengthText = 'Strong';
    
    // More encouraging thresholds
    if (strength < 25) {
      strengthColor = colorScheme.error;
      strengthText = 'Weak';
    } else if (strength < 50) {
      strengthColor = Colors.orange;
      strengthText = 'Fair';
    } else if (strength < 70) {
      strengthColor = Colors.amber;
      strengthText = 'Good';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength',
              style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            Text(
              strengthText,
              style: AppTheme.caption(strengthColor).copyWith(
                fontWeight: AppTheme.weightSemiBold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: strength / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
