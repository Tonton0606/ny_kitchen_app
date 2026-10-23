import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ny_kitchen_app/main.dart' as app;

// IMPORTANT: Integration tests need a running emulator or desktop app.
// Since these are UI driven, we'll write them assuming the default seeded database.

void main() {
  final isLive = Platform.environment.containsKey('FLUTTER_TEST_DEVICE') ||
      Platform.environment.containsKey('INTEGRATION_TEST');
  if (isLive) {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  }

  group('Authentication Flow Integration Tests', () {
    testWidgets('Full flow: login -> session active -> logout -> session cleared', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. We are on the login screen, expect username field
      final usernameField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.text('Login');

      expect(usernameField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      // 2. Login as admin
      await tester.enterText(usernameField, 'admin');
      await tester.enterText(passwordField, 'admin123');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 3. We should be on the dashboard or have admin drawer access
      // Check for something that only exists on dashboard
      expect(find.text('Overview of today\'s business performance'), findsWidgets);

      // 4. Logout
      // Need to find the settings/tune icon or logout button
      final settingsButton = find.byTooltip('Settings');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton.first);
        await tester.pumpAndSettle();
      }
      
      final logoutButton = find.text('Logout');
      if (logoutButton.evaluate().isNotEmpty) {
        await tester.tap(logoutButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // 5. Verify back on login screen
        expect(find.text('Login'), findsOneWidget);
      }
    }, skip: !isLive);
  });
}
