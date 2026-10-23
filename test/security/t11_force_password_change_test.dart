import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
        version: 1,
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
              face_encoding TEXT,
              must_change_password INTEGER DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE audit_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              username TEXT,
              role TEXT,
              module TEXT NOT NULL,
              action TEXT NOT NULL,
              status TEXT NOT NULL,
              description TEXT,
              ip_address TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    userRepo = UserRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('T-11: First-Login Forced Password Change Security Tests', () {
    test('User with must_change_password=1 has mustChangePassword session flag set', () async {
      final initialHash = SecurityUtils.hashPassword('DefaultPass1');
      await db.insert('users', {
        'id': 10,
        'full_name': 'New Cashier',
        'username': 'newcashier',
        'password_hash': initialHash,
        'role': 'cashier',
        'status': 'active',
        'must_change_password': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      final user = await userRepo.login('newcashier', 'DefaultPass1');
      expect(user, isNotNull);
      expect(user!['must_change_password'], equals(1));

      sessionManager.setSession(user);
      expect(sessionManager.mustChangePassword, isTrue);
    });

    test('changePassword updates hash and resets must_change_password to 0', () async {
      final initialHash = SecurityUtils.hashPassword('DefaultPass1');
      await db.insert('users', {
        'id': 11,
        'full_name': 'First Login Cashier',
        'username': 'firstcashier',
        'password_hash': initialHash,
        'role': 'cashier',
        'status': 'active',
        'must_change_password': 1,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Authenticate as this user
      final user = await userRepo.login('firstcashier', 'DefaultPass1');
      sessionManager.setSession(user!);

      // Change password to a strong password
      final success = await userRepo.changePassword(11, 'NewStrongPass2026!');
      expect(success, isTrue);

      // Verify DB record has must_change_password = 0 and new password hash verifies
      final updatedRows = await db.query('users', where: 'id = ?', whereArgs: [11]);
      final updatedUser = updatedRows.first;
      expect(updatedUser['must_change_password'], equals(0));
      expect(
        SecurityUtils.verifyPassword('NewStrongPass2026!', updatedUser['password_hash'] as String),
        isTrue,
      );
      expect(
        SecurityUtils.verifyPassword('DefaultPass1', updatedUser['password_hash'] as String),
        isFalse,
      );
    });
  });
}
