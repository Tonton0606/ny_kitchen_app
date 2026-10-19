import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/theme/app_theme.dart';
import 'package:ny_kitchen_app/features/auth/presentation/pages/login_page.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/force_change_password_dialog.dart';

void main() {
  Widget buildTestableWidget(Widget child, {double width = 1200, double height = 800}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
    );
  }

  group('Phase 4: Auth UI Tests', () {
    testWidgets('LoginPage renders branding, inputs, and tactile button without face biometric', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginPage()));
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email or username'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Login with Face'), findsNothing);
      expect(find.text('Remember Me'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('ForceChangePasswordDialog renders with design tokens and policy info', (tester) async {
      final user = {'id': 1, 'username': 'cashier1', 'must_change_password': 1};

      await tester.pumpWidget(
        buildTestableWidget(
          ForceChangePasswordDialog(
            user: user,
            onSuccess: () {},
            onCancel: () {},
          ),
          width: 500,
          height: 600,
        ),
      );
      await tester.pump();

      expect(find.text('Password Change Required'), findsOneWidget);
      expect(find.text('Cancel / Log Out'), findsOneWidget);
      expect(find.text('Set Password & Continue'), findsOneWidget);
    });
  });
}
