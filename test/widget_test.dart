import 'package:flutter/material.dart';
import 'package:authenticator/view/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:authenticator/services/database_service.dart';
import 'package:authenticator/services/account_service.dart';
import 'package:authenticator/services/totp_service.dart';
import 'package:authenticator/services/theme_service.dart';
import 'package:authenticator/view_models/account_view_model.dart';

void main() {
  testWidgets('Authenticator app smoke test', (WidgetTester tester) async {
    // Create services similar to main.dart providers (lightweight)
  final databaseService = DatabaseService();
    final accountService = AccountService(databaseService: databaseService);
    final totpService = TOTPService();
    final themeService = ThemeService();

    // Build our app wrapped in the same providers and trigger a frame.
    // For the widget test we pump a minimal app with HomeScreen directly
    // This avoids AuthWrapper async initialization and keeps the test stable.
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => themeService),
            ChangeNotifierProvider(
              create: (_) => AccountViewModel(
                accountService: accountService,
                totpService: totpService,
                autoInit: false, // avoid timers and DB calls in widget test
              ),
            ),
          ],
          child: const HomeScreen(),
        ),
      ),
    );

    // Allow a single frame to render
    await tester.pump();

    // Verify that the app title is displayed
    expect(find.text('Authenticator'), findsOneWidget);
    
    // Verify that the empty state is shown when no accounts exist
    expect(find.text('No 2FA Accounts'), findsOneWidget);
  });
}
