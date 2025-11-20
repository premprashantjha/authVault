import 'package:authenticator/models/account.dart';
import 'package:authenticator/view/widget/otp_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:io' show Platform;
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import '../app/theme.dart';
import '../view_models/account_view_model.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qr_scan_screen.dart';
import '../services/totp_service.dart';
import 'settings_screen.dart';
import '../animations/animation_service.dart';
import '../animations/custom_page_route.dart';
import '../widgets/animated/staggered_list.dart';
import '../widgets/animated/animated_fab.dart';
import '../widgets/animated/animated_button.dart';
import '../widgets/animated/skeleton.dart';
import '../widgets/custom_snackbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _fabOpen = false;
  final StaggeredListController<AccountWithOTP> _listController = StaggeredListController<AccountWithOTP>();
  
  @override
  void initState() {
    super.initState();
    _enableScreenshotPrevention();
    // Accounts are automatically loaded in the ViewModel constructor
  }

  /// Enable screenshot prevention (FLAG_SECURE) on Android
  Future<void> _enableScreenshotPrevention() async {
    if (!kDebugMode && Platform.isAndroid) {
      try {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      } catch (e) {
        // Silently fail - not critical
      }
    }
  }

  void _navigateToSettings(BuildContext context) async {
    // Capture navigator synchronously to avoid using BuildContext after awaits
    final navigator = Navigator.of(context);

    // Get auth service from context or create new instance
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(prefs: prefs);
    if (!mounted) return;

    await navigator.push(CustomPageRoute(page: SettingsScreen(authService: authService), style: PageTransitionStyle.scale));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Authenticator',
          style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: Consumer<AccountViewModel>(
        builder: (context, viewModel, child) {
          // Removed verbose debug logging that was triggered on every rebuild
          if (viewModel.isLoading) {
            // Show lightweight skeleton placeholders while accounts load
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  Skeleton(height: 88),
                  SizedBox(height: 12),
                  Skeleton(height: 88),
                  SizedBox(height: 12),
                  Skeleton(height: 88),
                ],
              ),
            );
          }

          if (!viewModel.hasAccounts) {
            return _buildEmptyState();
          }

          return _buildAccountsList(viewModel);
        },
      ),
      floatingActionButton: AnimatedFAB(
        isOpen: _fabOpen,
        onTap: () {
          setState(() => _fabOpen = !_fabOpen);
          _showAddAccountOptions(context).whenComplete(() {
            if (mounted) setState(() => _fabOpen = false);
          });
        },
        openIcon: const Icon(Icons.add, size: 28),
        closeIcon: const Icon(Icons.close, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lottie animation showing QR scan interaction
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Lottie.asset(
                    'assets/images/AuthenticatorWelcomeScreen.json',
                    fit: BoxFit.contain,
                    repeat: true,
                    animate: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No 2FA Accounts',
                  style: AppTheme.headlineLarge(theme.colorScheme.onSurface).copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Secure your accounts with two-factor authentication',
                  style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    height: 1.5,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AnimatedButton(
                  onTap: () => _showAddAccountOptions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.qr_code_scanner, size: 20, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'Add Your First Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountsList(AccountViewModel viewModel) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.security, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                '${viewModel.accountsWithOTP.length} Account${viewModel.accountsWithOTP.length == 1 ? '' : 's'}',
                style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Auto-refresh in ${viewModel.accountsWithOTP.isNotEmpty ? viewModel.accountsWithOTP.first.secondsRemaining : 30}s',
                style: AppTheme.caption(theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
        // Accounts List
        Expanded(
            child: Padding(
            padding: const EdgeInsets.all(16),
            child: StaggeredList<AccountWithOTP>(
              key: ValueKey('accounts_${viewModel.accountsWithOTP.length}'),
              controller: _listController,
              items: viewModel.accountsWithOTP,
              itemBuilder: (context, index, item, animation) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OTPCard(
                    account: item,
                    onDelete: () => _deleteAccount(context, item.account.id),
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAccountOptions(BuildContext context) {
    final theme = Theme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add Account',
                style: AppTheme.headlineMedium(theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Your secrets stay encrypted on this device. Keep a backup so you can restore them if you switch phones.',
                style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildAddOption(
                context,
                icon: Icons.qr_code_scanner,
                title: 'Scan QR Code',
                subtitle: 'Recommended. Point your camera at the QR code provided by the service.',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToQRScan(context);
                },
              ),
              const SizedBox(height: 16),
              _buildAddOption(
                context,
                icon: Icons.keyboard,
                title: 'Enter Manually',
                subtitle: 'Paste or type the secret key if you cannot scan.',
                onTap: () {
                  Navigator.pop(context);
                  _showManualEntryDialog(context);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surface.withValues(alpha: 0.8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: AppTheme.bodyLarge(theme.colorScheme.onSurface)),
        subtitle: Text(subtitle, style: AppTheme.caption(theme.colorScheme.onSurface)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
        onTap: onTap,
      ),
    );
  }

  void _navigateToQRScan(BuildContext context) async {
    await AnimationService.pushWithStyle(context, const QRScanScreen(), style: PageTransitionStyle.slideRight);
    // No explicit refresh needed - addAccount() in QR scan already calls _loadAccounts() which notifies listeners
  }

  void _showManualEntryDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Account', style: AppTheme.headlineMedium(theme.colorScheme.onSurface)),
        content: ManualEntryForm(
          onAccountAdded: (account) {
            Navigator.pop(dialogContext);
            // Use the parent context, not the dialog context
            _addAccount(account);
          },
        ),
      ),
    );
  }

  void _addAccount(Account account) async {
    final viewModel = context.read<AccountViewModel>();

    // Check duplicate early and provide a clear message
    final exists = await viewModel.accountExists(account);
    if (exists) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        title: account.issuer,
        message: 'This account is already in your vault',
        type: SnackbarType.info,
      );
      return;
    }

    final success = await viewModel.addAccount(account);

    if (!mounted) return;

    if (success) {
      CustomSnackbar.show(
        context,
        title: '${account.issuer} Added',
        message: 'Your account has been securely added to the vault',
        type: SnackbarType.success,
      );
    } else {
      CustomSnackbar.show(
        context,
        title: 'Failed',
        message: 'Unable to add account. Please try again.',
        type: SnackbarType.error,
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context, String accountId) async {
    final viewModel = context.read<AccountViewModel>();
    final index = viewModel.accountsWithOTP.indexWhere((a) => a.account.id == accountId);

    if (index != -1) {
      try {
        await _listController.removeAt(index, (removedItem, animation) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OTPCard(
              account: removedItem,
              onDelete: () {},
              onTap: () {},
            ),
          );
        });
      } catch (_) {
        // ignore animation errors and continue to delete
      }
    }

    final success = await viewModel.deleteAccount(accountId);
    if (!mounted) return;

    if (success) {
      CustomSnackbar.show(
        context,
        title: 'Account Deleted',
        message: 'This account and its OTPs were removed from Authenticator.',
        type: SnackbarType.error,
      );
    }
  }
}

// Manual Entry Form as a separate widget
class ManualEntryForm extends StatefulWidget {
  final Function(Account) onAccountAdded;

  const ManualEntryForm({super.key, required this.onAccountAdded});

  @override
  State<ManualEntryForm> createState() => _ManualEntryFormState();
}

class _ManualEntryFormState extends State<ManualEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _issuerController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _secretKeyController = TextEditingController();

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
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              labelStyle: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                child: Center(child: const Text('Add Account', style: TextStyle(color: Colors.white))),
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
      // Validate secret decodability before adding (give clearer feedback)
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

  @override
  void dispose() {
    _issuerController.dispose();
    _accountNameController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }
}