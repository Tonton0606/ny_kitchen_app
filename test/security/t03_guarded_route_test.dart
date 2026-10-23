import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:ny_kitchen_app/features/auth/presentation/pages/login_page.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/guarded_route.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('T-03: GuardedRoute Synchronous First-Frame Protection Tests', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      sessionManager.clearSession();
    });

    Widget buildTestHarness(List<String> allowedRoles) {
      return MaterialApp(
        home: Scaffold(
          body: GuardedRoute(
            allowedRoles: allowedRoles,
            child: const Text('SUPER_SECRET_PAYLOAD_CONTENT'),
          ),
        ),
      );
    }

    testWidgets('First-frame blocks unauthenticated user without leaking child', (tester) async {
      // Pump initial frame only (do NOT settle)
      await tester.pumpWidget(buildTestHarness(['admin']));

      // The child content must NOT exist in the widget tree on the first frame
      expect(find.text('SUPER_SECRET_PAYLOAD_CONTENT'), findsNothing);
      expect(find.byType(SizedBox), findsWidgets);

      // Settle allows the post-frame redirect to complete
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('First-frame blocks expired session synchronously', (tester) async {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'username': 'admin'});
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 45));

      await tester.pumpWidget(buildTestHarness(['admin']));

      expect(find.text('SUPER_SECRET_PAYLOAD_CONTENT'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('First-frame blocks user with mustChangePassword flag', (tester) async {
      sessionManager.setSession({
        'id': 2,
        'role': 'cashier',
        'username': 'cashier1',
        'must_change_password': 1,
      });

      await tester.pumpWidget(buildTestHarness(['cashier']));

      expect(find.text('SUPER_SECRET_PAYLOAD_CONTENT'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('First-frame blocks wrong role without leaking content', (tester) async {
      sessionManager.setSession({
        'id': 3,
        'role': 'cashier',
        'username': 'cashier2',
      });

      await tester.pumpWidget(buildTestHarness(['admin']));

      expect(find.text('SUPER_SECRET_PAYLOAD_CONTENT'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('First-frame renders child for valid authorized session', (tester) async {
      sessionManager.setSession({
        'id': 4,
        'role': 'admin',
        'username': 'admin',
      });

      await tester.pumpWidget(buildTestHarness(['admin']));

      // Renders immediately on frame 1 without delay
      expect(find.text('SUPER_SECRET_PAYLOAD_CONTENT'), findsOneWidget);
    });
  });
}
