import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:ny_kitchen_app/features/auth/presentation/pages/login_page.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/force_change_password_dialog.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/guarded_route.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ny_kitchen_app/core/utils/security_exception.dart';

void main() {
  late Database db;
  late UserRepository userRepo;
  late SessionManager sessionManager;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SecurityUtils.defaultIterations = 1000;
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDownAll(() {
    SecurityUtils.defaultIterations = SecurityUtils.targetIterations;
  });

  setUp(() async {
    sessionManager = SessionManager();
    sessionManager.clearSession();

    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              full_name TEXT NOT NULL,
              username TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              role TEXT NOT NULL,
              status TEXT NOT NULL,
              last_login TEXT,
              failed_login_count INTEGER DEFAULT 0,
              must_change_password INTEGER DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE activity_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              username TEXT,
              role TEXT,
              module TEXT NOT NULL,
              action TEXT NOT NULL,
              status TEXT NOT NULL,
              description TEXT,
              device_info TEXT,
              created_at TEXT NOT NULL
            )
          ''');

          final now = DateTime.now().toIso8601String();
          // Seeded accounts with must_change_password = 1 (Gap 3)
          await db.insert('users', {
            'full_name': 'System Administrator',
            'username': 'admin',
            'password_hash': SecurityUtils.hashPassword('admin123'),
            'role': 'admin',
            'status': 'active',
            'must_change_password': 1,
            'created_at': now,
          });
          await db.insert('users', {
            'full_name': 'Head Cashier',
            'username': 'cashier',
            'password_hash': SecurityUtils.hashPassword('cashier123'),
            'role': 'cashier',
            'status': 'active',
            'must_change_password': 1,
            'created_at': now,
          });
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    userRepo = UserRepository();
  });

  tearDown(() async {
    sessionManager.clearSession();
    await db.close();
  });

  group('A6 - Force Password Change on First Login (Gap 3)', () {
    test('Seeded admin and cashier accounts have must_change_password set to 1', () async {
      final adminUser = await userRepo.login('admin', 'admin123');
      expect(adminUser, isNotNull);
      expect(adminUser!['must_change_password'], equals(1),
          reason: 'Seeded admin must require password change on first login');

      final cashierUser = await userRepo.login('cashier', 'cashier123');
      expect(cashierUser, isNotNull);
      expect(cashierUser!['must_change_password'], equals(1),
          reason: 'Seeded cashier must require password change on first login');
    });

    test('UserRepository.changePassword updates password_hash and resets must_change_password to 0', () async {
      final user = await userRepo.login('admin', 'admin123');
      expect(user!['must_change_password'], equals(1));
      sessionManager.setSession(user);

      final success = await userRepo.changePassword(user['id'] as int, 'NewSecurePass1');
      expect(success, isTrue);

      final updatedUser = await userRepo.login('admin', 'NewSecurePass1');
      expect(updatedUser, isNotNull);
      expect(updatedUser!['must_change_password'], equals(0),
          reason: 'must_change_password must be reset to 0 once user changes their password');
    });

    test('UserRepository.createUser defaults must_change_password to 1', () async {
      sessionManager.setSession({'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'});
      final newUserId = await userRepo.createUser({
        'full_name': 'Jane Cashier',
        'username': 'janec',
        'password_hash': SecurityUtils.hashPassword('TempPass123'),
        'role': 'cashier',
        'status': 'active',
      });

      final rows = await db.query('users', where: 'id = ?', whereArgs: [newUserId]);
      expect(rows.first['must_change_password'], equals(1),
          reason: 'Newly created users must be forced to change temporary password on first login');
    });

    test('SessionManager.mustChangePassword reflects user state', () {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'must_change_password': 1});
      expect(sessionManager.mustChangePassword, isTrue);

      sessionManager.setSession({'id': 1, 'role': 'admin', 'must_change_password': 0});
      expect(sessionManager.mustChangePassword, isFalse);
    });

    testWidgets('GuardedRoute blocks access and redirects to Login when mustChangePassword is true', (WidgetTester tester) async {
      sessionManager.setSession({
        'id': 1,
        'role': 'admin',
        'full_name': 'Admin User',
        'must_change_password': 1,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: GuardedRoute(
            allowedRoles: const ['admin'],
            child: const Scaffold(body: Text('Protected Admin Content')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Protected Admin Content'), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('ForceChangePasswordDialog enforces password policy and completes callback on valid password', (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1200, 1000);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool successCalled = false;
      final testUser = {
        'id': 1,
        'username': 'admin',
        'must_change_password': 1,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForceChangePasswordDialog(
              user: testUser,
              onSuccess: () => successCalled = true,
              onCancel: () {},
              onSavePassword: (id, newPass) async {
                return true;
              },
            ),
          ),
        ),
      );

      // 1. Submit empty -> error
      await tester.tap(find.text('Set Password & Continue'));
      await tester.pump();
      expect(find.text('Please fill out both password fields'), findsOneWidget);

      // 2. Submit non-matching passwords
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Pass1234');
      await tester.enterText(textFields.at(1), 'Different123');
      await tester.tap(find.text('Set Password & Continue'));
      await tester.pump();
      expect(find.text('Passwords do not match'), findsOneWidget);

      // 3. Submit default credential 'admin123'
      await tester.enterText(textFields.at(0), 'admin123');
      await tester.enterText(textFields.at(1), 'admin123');
      await tester.tap(find.text('Set Password & Continue'));
      await tester.pump();
      expect(find.text('Cannot reuse default or trivial credentials'), findsOneWidget);

      // 4. Submit weak password (no digit)
      await tester.enterText(textFields.at(0), 'lettersOnly');
      await tester.enterText(textFields.at(1), 'lettersOnly');
      await tester.tap(find.text('Set Password & Continue'));
      await tester.pump();
      expect(find.text(SecurityUtils.passwordPolicyMessage), findsOneWidget);

      // 5. Submit valid password
      await tester.enterText(textFields.at(0), 'SecureNewPassword99');
      await tester.enterText(textFields.at(1), 'SecureNewPassword99');
      await tester.ensureVisible(find.text('Set Password & Continue'));
      await tester.tap(find.text('Set Password & Continue'));
      await tester.pump();

      expect(successCalled, isTrue);
      expect(testUser['must_change_password'], equals(0));
    });

    test('UserRepository.changePassword throws UNAUTHENTICATED when session is null', () async {
      final user = await userRepo.login('cashier', 'cashier123');
      expect(user!['must_change_password'], equals(1));
      sessionManager.clearSession();

      expect(
        () => userRepo.changePassword(user['id'] as int, 'Hancejabezpogi123'),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
    });

    test('UserRepository.changePassword succeeds and clears must_change_password when session is set', () async {
      final user = await userRepo.login('cashier', 'cashier123');
      expect(user!['must_change_password'], equals(1));
      sessionManager.setSession(user);

      final success = await userRepo.changePassword(user['id'] as int, 'Hancejabezpogi123');
      expect(success, isTrue);

      final updated = await userRepo.login('cashier', 'Hancejabezpogi123');
      expect(updated, isNotNull);
      expect(updated!['must_change_password'], equals(0));
    });
  });
}

