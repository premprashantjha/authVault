import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/platform_backup_service.dart';

/// Simplified password setup dialog
/// 
/// Features:
/// - Real-time password strength indicator
/// - Show/hide password toggle
/// - Confirmation validation
/// - Responsive and scrollable
class BackupPasswordSetupDialog extends StatefulWidget {
  final String? title;
  final String? description;

  const BackupPasswordSetupDialog({
    super.key,
    this.title,
    this.description,
  });

  @override
  State<BackupPasswordSetupDialog> createState() => _BackupPasswordSetupDialogState();
}

class _BackupPasswordSetupDialogState extends State<BackupPasswordSetupDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _passwordStrength = 0;
  String? _passwordWarning;
  bool _passwordsMatch = true;
  
  // Cache platform account - fetch once
  String? _platformAccount;
  bool _isLoadingAccount = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    _confirmController.addListener(_checkPasswordsMatch);
    _loadPlatformAccount(); // Fetch once on init
  }
  
  Future<void> _loadPlatformAccount() async {
    try {
      final account = await PlatformBackupService.getPrimaryAccount();
      if (mounted) {
        setState(() {
          _platformAccount = account;
          _isLoadingAccount = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _platformAccount = null;
          _isLoadingAccount = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      final password = _passwordController.text;
      _passwordStrength = _estimatePasswordStrength(password);
      _passwordWarning = _getPasswordWarning(password);
    });
  }

  /// Simple password strength estimation
  int _estimatePasswordStrength(String password) {
    if (password.length < 8) return 0;
    if (password.length < 12) return 1;
    if (password.length >= 16) return 3;
    return 2;
  }

  /// Get password warning message
  String? _getPasswordWarning(String password) {
    if (password.isEmpty) return null;
    if (password.length < 8) return 'Too short';
    if (password.length < 12) return 'Could be stronger';
    return null;
  }

  void _checkPasswordsMatch() {
    setState(() {
      _passwordsMatch = _passwordController.text == _confirmController.text;
    });
  }

  void _handleConfirm() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    
    // Validate
    final error = _validatePassword(password);
    if (error != null) {
      _showError(error);
      return;
    }
    
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }
    
    // Show warning if weak password
    if (_passwordStrength < 50 && _passwordWarning != null) {
      _showWeakPasswordWarning(password);
      return;
    }
    
    Navigator.of(context).pop(password);
  }

  /// Validate password meets requirements
  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _showWeakPasswordWarning(String password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Weak Password'),
        content: Text(
          '$_passwordWarning\n\n'
          'Are you sure you want to use this password?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Change Password'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(password);
            },
            child: const Text('Use Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.title ?? 'Set Backup Password',
                  style: AppTheme.headlineMedium(colorScheme.onSurface).copyWith(
                    fontWeight: AppTheme.weightBold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  widget.description ?? 'Create a password to protect your accounts',
                  style: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 16),
                
                // Google Account Info (cached, not fetched repeatedly)
                if (_isLoadingAccount)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Loading account...',
                            style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_platformAccount != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            PlatformBackupService.accountIcon,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${PlatformBackupService.backupProviderName} Account',
                                  style: AppTheme.caption(colorScheme.primary).copyWith(
                                    fontWeight: AppTheme.weightSemiBold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _platformAccount!,
                                  style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.8)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Password field
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTheme.bodyMedium(colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter a strong password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _handleConfirm(),
                ),
                const SizedBox(height: 16),
                
                // Password strength indicator
                if (_passwordController.text.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _passwordStrength / 100,
                            minHeight: 6,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getStrengthColor(_passwordStrength, colorScheme),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getStrengthText(_passwordStrength),
                        style: AppTheme.caption(
                          _getStrengthColor(_passwordStrength, colorScheme),
                        ).copyWith(fontWeight: AppTheme.weightSemiBold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Confirm password field
                TextField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  style: AppTheme.bodyMedium(colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorText: _confirmController.text.isNotEmpty && !_passwordsMatch
                        ? 'Passwords do not match'
                        : null,
                  ),
                  onSubmitted: (_) => _handleConfirm(),
                ),
                const SizedBox(height: 20),
                
                // Warning
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Store this password safely. It cannot be recovered if lost.',
                          style: AppTheme.caption(colorScheme.error),
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
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _passwordController.text.length >= 6 && _passwordsMatch
                            ? _handleConfirm
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStrengthColor(int strength, ColorScheme colorScheme) {
    if (strength < 30) return colorScheme.error;
    if (strength < 50) return Colors.orange;
    if (strength < 70) return Colors.amber;
    return Colors.green;
  }

  String _getStrengthText(int strength) {
    if (strength < 30) return 'Weak';
    if (strength < 50) return 'Fair';
    if (strength < 70) return 'Good';
    return 'Strong';
  }
}
