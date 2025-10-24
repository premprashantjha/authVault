import 'package:authvault_poc/services/qr_scanner_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../view_models/account_view_model.dart';
import '../services/totp_service.dart';
import 'qr_scan_screen.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _issuerController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _totpService = TOTPService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Account'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // QR Scan Button
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: _scanQRCode,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 40, color: Colors.blue),
                      const SizedBox(height: 8),
                      const Text(
                        'Scan QR Code',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Or enter details manually',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Issuer (e.g., Google)',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Account Name (e.g., user@gmail.com)',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Secret Key (Base32)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter your secret key',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a secret key';
                  }
                  if (!_totpService.validateSecret(value)) {
                    return 'Invalid secret key format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _addAccount,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Add Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _scanQRCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScanScreen()),
    );

    if (result != null && result is OTPAuthURI) {
      _fillFormFromQR(result);
    }
  }

  void _fillFormFromQR(OTPAuthURI otpAuth) {
    setState(() {
      _issuerController.text = otpAuth.issuer;
      _accountNameController.text = otpAuth.account;
      _secretKeyController.text = otpAuth.secret;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR Code scanned successfully!')),
    );
  }

  void _addAccount() async {
    if (_formKey.currentState!.validate()) {
      final account = Account(
        issuer: _issuerController.text.trim(),
        accountName: _accountNameController.text.trim(),
        secretKey: _secretKeyController.text.trim().toUpperCase(),
      );

      final success = await context.read<AccountViewModel>().addAccount(account);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account added successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add account')),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }
}