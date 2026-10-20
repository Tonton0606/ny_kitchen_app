import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/biometric_consent_dialog.dart';
import 'package:ny_kitchen_app/features/shared/widgets/app_buttons.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserRepository userRepository;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
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
              face_encoding TEXT,
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
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    userRepository = UserRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('Fix 2 - Biometric Hard Deletion & Audit Trail', () {
    const rawVectorJson = '{"vector":[0.111, 0.222, -0.333, 0.444]}';

    test('deleteBiometricProfile sets face_encoding to NULL and creates audit log', () async {
      final encrypted = await SecurityUtils.encryptFaceEncoding(rawVectorJson);
      final userId = await db.insert('users', {
        'full_name': 'Cashier Biometric User',
        'username': 'cashier_bio',
        'password_hash': 'test_hash',
        'role': 'cashier',
        'status': 'active',
        'face_encoding': encrypted,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Verify face_encoding is initially present
      final before = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      expect(before.first['face_encoding'], isNotNull);

      // Perform deletion
      await userRepository.deleteBiometricProfile(userId, adminName: 'Admin Alice');

      // Verify face_encoding is hard-deleted (NULL)
      final after = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      expect(after.first['face_encoding'], isNull,
          reason: 'Biometric template must be cleared to NULL in SQLite');

      // Verify audit log entry
      final logs = await db.query(
        'activity_logs',
        where: 'action = ?',
        whereArgs: ['Biometric Profile Deleted'],
      );
      expect(logs.length, equals(1));
      final log = logs.first;
      expect(log['module'], equals('Security'));
      expect(log['description'], contains('Admin Alice'));

      // CRITICAL: Ensure biometric vectors or ciphers are NEVER leaked into logs
      final allLogText = jsonEncode(log);
      expect(allLogText.contains('0.111'), isFalse, reason: 'Log must not contain raw vector numbers');
      expect(allLogText.contains(encrypted), isFalse, reason: 'Log must not contain encrypted ciphertext');
      expect(allLogText.contains('v2:'), isFalse, reason: 'Log must not contain v2 payload');
    });

    test('updateFaceEncoding audits enrollment without leaking biometric vector', () async {
      final userId = await db.insert('users', {
        'full_name': 'Cashier Enrolling User',
        'username': 'cashier_enroll',
        'password_hash': 'test_hash',
        'role': 'cashier',
        'status': 'active',
        'face_encoding': null,
        'created_at': DateTime.now().toIso8601String(),
      });

      await userRepository.updateFaceEncoding(userId, rawVectorJson, adminName: 'Admin Alice');

      final userRow = (await db.query('users', where: 'id = ?', whereArgs: [userId])).first;
      expect(userRow['face_encoding'], isNotNull);
      expect((userRow['face_encoding'] as String).startsWith('v2:'), isTrue);

      final logs = await db.query(
        'activity_logs',
        where: 'action = ?',
        whereArgs: ['Biometric Enrolled'],
      );
      expect(logs.length, equals(1));
      final allLogText = jsonEncode(logs.first);
      expect(allLogText.contains('0.111'), isFalse, reason: 'Audit log must never store biometric vectors');
    });
  });

  group('Fix 2 - BiometricConsentDialog UI & Logic', () {
    testWidgets('Consent dialog disables accept button until acknowledged; decline returns false', (tester) async {
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await BiometricConsentDialog.show(
                    context,
                    targetUserName: 'John Doe',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify title & info
      expect(find.text('Biometric Consent for John Doe'), findsOneWidget);
      expect(find.text('Local AES-256-GCM Encryption'), findsOneWidget);
      expect(find.text('No Cloud Transmission'), findsOneWidget);
      expect(find.text('Right to Permanent Erasure'), findsOneWidget);

      // Verify "Accept & Proceed" button exists
      final acceptButtonFinder = find.widgetWithText(AppPrimaryButton, 'Accept & Proceed');
      expect(acceptButtonFinder, findsOneWidget);
      final acceptButton = tester.widget<AppPrimaryButton>(acceptButtonFinder);
      expect(acceptButton.onPressed, isNull, reason: 'Must be disabled before checkbox is checked');

      // Click Decline
      await tester.tap(find.text('Decline'));
      await tester.pumpAndSettle();

      expect(dialogResult, isFalse, reason: 'Declining must return false');
    });

    testWidgets('Checking consent checkbox enables Accept & Proceed which returns true', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await BiometricConsentDialog.show(
                    context,
                    targetUserName: 'Jane Doe',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap the acknowledgment checkbox
      final checkboxFinder = find.byType(Checkbox);
      expect(checkboxFinder, findsOneWidget);
      await tester.ensureVisible(checkboxFinder);
      await tester.pumpAndSettle();
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Now "Accept & Proceed" should be enabled
      final acceptButtonFinder = find.widgetWithText(AppPrimaryButton, 'Accept & Proceed');
      final acceptButton = tester.widget<AppPrimaryButton>(acceptButtonFinder);
      expect(acceptButton.onPressed, isNotNull, reason: 'Must be enabled after checking consent');

      // Tap Accept & Proceed
      await tester.tap(acceptButtonFinder);
      await tester.pumpAndSettle();

      expect(dialogResult, isTrue, reason: 'Accepting must return true');
    });
  });
}
