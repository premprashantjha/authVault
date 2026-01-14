import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../app/app_constants.dart';

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
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  int _passwordStrength = 0;
  bool _passwordTouched = false; // Track if user has interacted
  bool _confirmTouched = false; // Track if user has interacted

  @override
  void initState() {
    super.initState();
    // Track when fields lose focus (user finished typing)
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

  void _onPasswordChanged(String value) {
    setState(() {
      _passwordStrength = _estimatePasswordStrength(value);
      _passwordError = null;
      // Mark as touched once user starts typing
      if (value.isNotEmpty && !_passwordTouched) {
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
    if (!widget.isCreating) return null;
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
    if (!widget.isCreating) return null;
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

  /// Validate password meets requirements
  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password is required';
    if (password.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  void _onConfirm() {
    final password = _passwordController.text;
    
    // Basic validation (just minimum requirements)
    final error = _validatePassword(password);
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
    
    // Return password
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(password);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRetry = widget.description.contains('Incorrect') || widget.description.contains('Try again');
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.getResponsiveRadius(context, large: 24.0))
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppConstants.getResponsiveDialogMaxWidth(context),
          maxHeight: MediaQuery.of(context).size.height * 0.9, // Max 90% of screen height
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.getResponsiveDialogPadding(context)),
            child: Column(
              mainAxisSize: MainAxisSize.min, // CRITICAL: Let content determine size
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Retry warning banner
                if (isRetry) ...[
                  Container(
                    padding: EdgeInsets.all(AppConstants.getResponsiveSpacing(context)),
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
                            style: AppTheme.responsiveCaption(context, colorScheme.onSurface).copyWith(
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
                      mainAxisSize: MainAxisSize.min, // CRITICAL: Size to content
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
                focusNode: _passwordFocusNode,
                obscureText: _obscurePassword,
                autofocus: true,
                style: AppTheme.bodyMedium(colorScheme.onSurface),
                cursorColor: colorScheme.primary,
                onChanged: _onPasswordChanged,
                onSubmitted: (_) => widget.isCreating ? null : _onConfirm(),
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
                  focusNode: _confirmFocusNode,
                  obscureText: _obscureConfirm,
                  style: AppTheme.bodyMedium(colorScheme.onSurface),
                  cursorColor: colorScheme.primary,
                  onChanged: _onConfirmChanged,
                  onSubmitted: (_) => _onConfirm(),
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
    )
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
    Color strengthColor = AppTheme.successColor;
    String strengthText = 'Very Strong';
    
    // More encouraging thresholds
    if (strength < 40) {
      strengthColor = colorScheme.error;
      strengthText = 'Too Short';
    } else if (strength < 60) {
      strengthColor = Colors.orange;
      strengthText = 'Good';
    } else if (strength < 80) {
      strengthColor = Colors.amber;
      strengthText = 'Strong';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // CRITICAL: Size to content
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
