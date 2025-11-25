import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/account.dart';
import '../../services/totp_service.dart';
import 'animated_button.dart';
import '../../widgets/custom_snackbar.dart';

class ManualEntryForm extends StatefulWidget {
  final Function(Account) onAccountAdded;

  const ManualEntryForm({
    super.key,
    required this.onAccountAdded,
  });

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _issuerController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _secretKeyController = TextEditingController();

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _issuerController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Issuer (e.g., Google)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an issuer';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _accountNameController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Account Name (e.g., user@gmail.com)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an account name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _secretKeyController,
            style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Secret Key (Base32)',
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'JBSWY3DPEHPK3PXP',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a secret key';
              }
              // Basic Base32 validation
              if (!RegExp(r'^[A-Z2-7]+=*$').hasMatch(value.toUpperCase())) {
                return 'Invalid secret key format';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AnimatedButton(
              onTap: _addAccount,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Add Account',
                    style: AppTheme.bodyMedium(theme.colorScheme.onPrimary).copyWith(
                      fontWeight: AppTheme.weightSemiBold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addAccount() {
    if (_formKey.currentState!.validate()) {
      final account = Account(
        issuer: _issuerController.text.trim(),
        accountName: _accountNameController.text.trim(),
        secretKey: _secretKeyController.text.trim().toUpperCase(),
      );
      
      // Validate secret decodability before adding
      final totp = TOTPService();
      if (!totp.validateSecret(account.secretKey)) {
        CustomSnackbar.show(
          context,
          title: 'Invalid Secret Key',
          message: 'Please check the Base32 format and try again',
          type: SnackbarType.error,
        );
        return;
      }

      widget.onAccountAdded(account);
    }
  }
}
