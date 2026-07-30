import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/guarded_route.dart';
import 'package:ny_kitchen_app/features/auth/presentation/pages/login_page.dart';

import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('Authorization Guard Tests', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      sessionManager.clearSession();
    });

    Widget createTestWidget(List<String> allowedRoles) {
      return MaterialApp(
        home: GuardedRoute(
          allowedRoles: allowedRoles,
          child: const Scaffold(
            body: Text('Protected Content'),
          ),
        ),
      );
    }

    testWidgets('GuardedRoute blocks cashier from admin pages', (WidgetTester tester) async {
      sessionManager.setSession({'id': 1, 'role': 'cashier', 'full_name': 'Test Cashier'});
      
      await tester.pumpWidget(createTestWidget(['admin']));
      await tester.pumpAndSettle(); // Allow post-frame callback and navigation

      expect(find.text('Protected Content'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Expired session → redirect to login', (WidgetTester tester) async {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'full_name': 'Test Admin'});
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 31)); // expired
      
      await tester.pumpWidget(createTestWidget(['admin']));
      await tester.pumpAndSettle();

      expect(find.text('Protected Content'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('Valid session → renders child widget', (WidgetTester tester) async {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'full_name': 'Test Admin'});
      
      await tester.pumpWidget(createTestWidget(['admin']));
      await tester.pumpAndSettle();

      expect(find.text('Protected Content'), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });
  });
}
