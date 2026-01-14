import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../services/recovery_codes_service.dart';
import '../widgets/custom_snackbar.dart';

class RecoveryCodesScreen extends StatefulWidget {
  const RecoveryCodesScreen({super.key});

  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  final RecoveryCodesService _recoveryService = RecoveryCodesService();
  bool _isLoading = true;
  bool _hasRecoveryCodes = false;
  int _remainingCodes = 0;
  List<String>? _generatedCodes;
  bool _codesAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _loadRecoveryStatus();
  }

  Future<void> _loadRecoveryStatus() async {
    setState(() => _isLoading = true);

    try {
      final hasCode = await _recoveryService.hasRecoveryCodes();
      final remaining = await _recoveryService.getRemainingCodesCount();

      setState(() {
        _hasRecoveryCodes = hasCode;
        _remainingCodes = remaining;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildGenerateConfirmDialog(),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final codes = await _recoveryService.generateRecoveryCodes();

      setState(() {
        _generatedCodes = codes;
        _hasRecoveryCodes = true;
        _remainingCodes = codes.length;
        _codesAcknowledged = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Failed to generate recovery codes: $e',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _regenerateCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildRegenerateConfirmDialog(),
    );

    if (confirmed != true) return;

    await _generateCodes();
  }

  Future<void> _deleteCodes() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _recoveryService.deleteRecoveryCodes();
      await _loadRecoveryStatus();

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Recovery codes deleted',
        type: SnackbarType.info,
      );
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Failed to delete recovery codes: $e',
        type: SnackbarType.error,
      );
    }
  }

  void _copyAllCodes() {
    if (_generatedCodes == null) return;

    final codesText = _generatedCodes!.join('\n');
    Clipboard.setData(ClipboardData(text: codesText));

    CustomSnackbar.show(
      context,
      message: 'Recovery codes copied to clipboard',
      type: SnackbarType.success,
    );
  }

  void _acknowledgeAndClose() {
    if (_generatedCodes == null) return;

    setState(() {
      _codesAcknowledged = true;
      _generatedCodes = null;
    });
  }

  Widget _buildGenerateConfirmDialog() {
    return AlertDialog(
      title: const Text('Generate Recovery Codes?'),
      content: const Text(
        'Recovery codes are one-time use codes that can help you regain access to your accounts if you lose your device or account access.\n\n'
        'You will see these codes only once. Make sure to save them in a secure location.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Generate'),
        ),
      ],
    );
  }

  Widget _buildRegenerateConfirmDialog() {
    return AlertDialog(
      title: const Text('Regenerate Recovery Codes?'),
      content: const Text(
        'This will invalidate all existing recovery codes and generate new ones.\n\n'
        'Any unused codes from the previous set will no longer work.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.warningColor,
          ),
          child: const Text('Regenerate'),
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmDialog() {
    return AlertDialog(
      title: const Text('Delete Recovery Codes?'),
      content: const Text(
        'This will permanently delete all recovery codes.\n\n'
        'You won\'t be able to use them for account recovery.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Show generated codes screen
    if (_generatedCodes != null) {
      return _buildGeneratedCodesScreen(theme);
    }

    // Show main recovery codes screen
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Recovery Codes',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                Card(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What are recovery codes?',
                                style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Recovery codes are one-time use codes that can help you regain access if you lose your device or account access.',
                                style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status Section
                if (_hasRecoveryCodes) ...[
                  Text(
                    'STATUS',
                    style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: theme.colorScheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppTheme.successColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recovery codes active',
                                  style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_remainingCodes codes remaining',
                                  style: AppTheme.caption(theme.colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Actions Section
                Text(
                  'ACTIONS',
                  style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                if (!_hasRecoveryCodes)
                  _buildActionCard(
                    context,
                    icon: Icons.add_circle_outline,
                    title: 'Generate Recovery Codes',
                    subtitle: 'Create 10 one-time use recovery codes',
                    color: theme.colorScheme.primary,
                    onTap: _generateCodes,
                  )
                else ...[
                  _buildActionCard(
                    context,
                    icon: Icons.refresh,
                    title: 'Regenerate Codes',
                    subtitle: 'Create new codes and invalidate old ones',
                    color: AppTheme.warningColor,
                    onTap: _regenerateCodes,
                  ),
                  const SizedBox(height: 8),
                  _buildActionCard(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Delete Recovery Codes',
                    subtitle: 'Permanently remove all recovery codes',
                    color: Colors.red,
                    onTap: _deleteCodes,
                  ),
                ],

                const SizedBox(height: 24),

                // How to Use Section
                Text(
                  'HOW TO USE',
                  style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  color: theme.colorScheme.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHowToStep(context, '1', 'Save codes in a secure location'),
                        const SizedBox(height: 12),
                        _buildHowToStep(context, '2', 'Each code can only be used once'),
                        const SizedBox(height: 12),
                        _buildHowToStep(context, '3', 'Use codes when you lose device access'),
                        const SizedBox(height: 12),
                        _buildHowToStep(context, '4', 'Regenerate codes if you run out'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGeneratedCodesScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: _codesAcknowledged ? () => Navigator.of(context).pop() : null,
        ),
        title: Text(
          'Your Recovery Codes',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Warning Card
                Card(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.warningColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Save these codes now!',
                                style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You will only see these codes once. Save them in a secure location like a password manager.',
                                style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recovery Codes List
                Text(
                  'RECOVERY CODES',
                  style: AppTheme.caption(theme.colorScheme.onSurface).copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),

                ..._generatedCodes!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final code = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      color: theme.colorScheme.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.copy,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                size: 20,
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: code));
                                CustomSnackbar.show(
                                  context,
                                  message: 'Code copied',
                                  type: SnackbarType.success,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _copyAllCodes,
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Copy All Codes'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _acknowledgeAndClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'I\'ve Saved These Codes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
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
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowToStep(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
