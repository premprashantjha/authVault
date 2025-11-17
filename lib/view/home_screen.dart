import 'package:authenticator/models/account.dart';
import 'package:authenticator/view/widget/otp_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // Accounts are automatically loaded in the ViewModel constructor
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
          debugPrint('HomeScreen Consumer rebuild: isLoading=${viewModel.isLoading}, hasAccounts=${viewModel.hasAccounts}, count=${viewModel.accountsWithOTP.length}');
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
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'No 2FA Accounts',
              style: AppTheme.headlineLarge(theme.colorScheme.onSurface).copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Add your first account to start securing your logins with two-factor authentication',
              style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AnimatedButton(
              onTap: () => _showAddAccountOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add Account', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
              const Icon(Icons.security, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                '${viewModel.accountsWithOTP.length} Account${viewModel.accountsWithOTP.length == 1 ? '' : 's'}',
                style: AppTheme.bodyLarge(theme.colorScheme.onSurface).copyWith(
                  color: AppTheme.primaryColor,
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
              const SizedBox(height: 24),
              _buildAddOption(
                context,
                icon: Icons.qr_code_scanner,
                title: 'Scan QR Code',
                subtitle: 'Quick setup with camera',
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
                subtitle: 'Add secret key manually',
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
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
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
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Add Account', style: AppTheme.headlineMedium(theme.colorScheme.onSurface)),
        content: ManualEntryForm(
          onAccountAdded: (account) {
            Navigator.pop(context);
            _addAccount(context, account);
          },
        ),
      ),
    );
  }

  void _addAccount(BuildContext context, Account account) async {
    final viewModel = context.read<AccountViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    // Check duplicate early and provide a clear message
    final exists = await viewModel.accountExists(account);
    if (exists) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Account already exists'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final success = await viewModel.addAccount(account);

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${account.issuer} account added successfully!'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Failed to add account'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _deleteAccount(BuildContext context, String accountId) {
    final theme = Theme.of(context);

  // Capture the current view model and index synchronously to avoid using
    // BuildContext across async gaps inside the dialog callbacks.
    final viewModel = context.read<AccountViewModel>();
    final index = viewModel.accountsWithOTP.indexWhere((a) => a.account.id == accountId);
  final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: AppTheme.headlineMedium(theme.colorScheme.onSurface)),
        content: Text(
          'Are you sure you want to delete this account? This action cannot be undone.',
          style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // If we have a valid index and a list controller, animate removal first,
              // then perform the authoritative deletion in the ViewModel.
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
                messenger.showSnackBar(
                  SnackBar(
                    content: const Text('Account deleted'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: Text('Delete', style: AppTheme.bodyMedium(theme.colorScheme.onSurface)),
          ),
        ],
      ),
    );
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
                  color: AppTheme.primaryColor,
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
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(content: const Text('Invalid secret key. Please check Base32 format.'), backgroundColor: AppTheme.errorColor),
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