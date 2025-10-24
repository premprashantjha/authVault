import 'package:authvault_poc/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AuthVault app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AuthVaultApp());

    // Verify that the app title is displayed
    expect(find.text('AuthVault'), findsOneWidget);
    
    // Verify that the empty state is shown when no accounts exist
    expect(find.text('No 2FA Accounts'), findsOneWidget);
  });
}
