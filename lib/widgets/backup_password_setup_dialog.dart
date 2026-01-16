import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';

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
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _passwordStrength = 0;
  String? _passwordError;
  bool _passwordTouched = false;
  bool _confirmTouched = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
    
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
        setState(() => _passwordTouched = true);
      }
    });
    _confirmFocusNode.addListener(() {
      if (!_confirmFocusNode.hasFocus && _confirmController.text.isNotEmpty) {
        setState(() => _confirmTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    setState(() {
      final password = _passwordController.text;
      _passwordStrength = _estimatePasswordStrength(password);
      _passwordError = null;
      
      // Mark as touched once user starts typing
      if (password.isNotEmpty && !_passwordTouched) {
        _passwordTouched = true;
      }
    });
  }

  void _onConfirmChanged(String value) {
    setState(() {
      _passwordError = null;
      // Mark as touched once user starts typing
      if (value.isNotEmpty && !_confirmTouched) {
        _confirmTouched = true;
      }
    });
  }

  /// Get inline hint for password field (shown while typing)
  String? _getPasswordHint() {
    if (!_passwordTouched) return null;
    
    final password = _passwordController.text;
    if (password.isEmpty) return null;
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Get inline hint for confirm field (shown while typing)
  String? _getConfirmHint() {
    if (!_confirmTouched) return null;
    
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    
    if (confirm.isEmpty) return null;
    if (password != confirm) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Simple password strength estimation (0-100 scale)
  /// More lenient and encouraging for users
  int _estimatePasswordStrength(String password) {
    int strength = 0;
    
    // Length scoring (more generous)
    if (password.length >= 8) strength += 40;  // Good start!
    if (password.length >= 10) strength += 20; // Even better
    if (password.length >= 12) strength += 20; // Great!
    if (password.length >= 16) strength += 10; // Excellent!
    
    // Bonus for variety (but not required)
    if (password.contains(RegExp(r'[A-Z]'))) strength += 5;  // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) strength += 5;  // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) strength += 5;  // Numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 5; // Special chars
    
    return strength.clamp(0, 100);
  }

  void _handleConfirm() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    
    // Validate and show inline error
    final error = _validatePassword(password);
    if (error != null) {
      setState(() => _passwordError = error);
      HapticFeedback.heavyImpact();
      return;
    }
    
    if (password != confirm) {
      setState(() => _passwordError = 'Passwords do not match');
      HapticFeedback.heavyImpact();
      return;
    }
    
    // Return password
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(password);
  }

  /// Validate password meets requirements
  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
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
                
                // Password field
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  obscureText: _obscurePassword,
                  autofocus: true,
                  style: AppTheme.bodyMedium(colorScheme.onSurface),
                  cursorColor: colorScheme.primary,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                    hintText: 'At least 8 characters',
                    hintStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.5)),
                    helperText: _getPasswordHint(),
                    helperStyle: _getPasswordHint() != null 
                        ? AppTheme.caption(colorScheme.error)
                        : null,
                    prefixIcon: Icon(Icons.lock, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getPasswordHint() != null 
                            ? colorScheme.error.withValues(alpha: 0.5)
                            : colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getPasswordHint() != null 
                            ? colorScheme.error
                            : colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleConfirm(),
                ),
                
                // Error message
                if (_passwordError != null) ...[
                  const SizedBox(height: 8),
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
                
                const SizedBox(height: 16),
                
                // Password strength indicator
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Password Strength',
                        style: AppTheme.caption(colorScheme.onSurface.withValues(alpha: 0.7)),
                      ),
                      Text(
                        _getStrengthText(_passwordStrength),
                        style: AppTheme.caption(
                          _getStrengthColor(_passwordStrength, colorScheme),
                        ).copyWith(fontWeight: AppTheme.weightSemiBold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
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
                ],
                
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmController,
                  focusNode: _confirmFocusNode,
                  obscureText: _obscureConfirm,
                  style: AppTheme.bodyMedium(colorScheme.onSurface),
                  cursorColor: colorScheme.primary,
                  onChanged: _onConfirmChanged,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.7)),
                    hintText: 'Re-enter password',
                    hintStyle: AppTheme.bodyMedium(colorScheme.onSurface.withValues(alpha: 0.5)),
                    helperText: _getConfirmHint(),
                    helperStyle: _getConfirmHint() != null 
                        ? AppTheme.caption(colorScheme.error)
                        : null,
                    prefixIcon: Icon(Icons.lock, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getConfirmHint() != null 
                            ? colorScheme.error.withValues(alpha: 0.5)
                            : colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _getConfirmHint() != null 
                            ? colorScheme.error
                            : colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _handleConfirm(),
                ),
                
                const SizedBox(height: 16),
                
                // Security notice
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
                          'This password encrypts your backup. Store it securely - it cannot be recovered if lost.',
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
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _handleConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirm',
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
      ),
    );
  }

  Color _getStrengthColor(int strength, ColorScheme colorScheme) {
    if (strength < 40) return colorScheme.error;      // Less than 8 chars
    if (strength < 60) return Colors.orange;          // 8-9 chars
    if (strength < 80) return Colors.amber;           // 10-11 chars
    return AppTheme.successColor;                     // 12+ chars or with variety
  }

  String _getStrengthText(int strength) {
    if (strength < 40) return 'Too Short';
    if (strength < 60) return 'Good';
    if (strength < 80) return 'Strong';
    return 'Very Strong';
  }
}
