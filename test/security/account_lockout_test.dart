import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late UserRepository userRepository;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SecurityUtils.defaultIterations = 1000;
    
    // We need to initialize flutter_secure_storage Mock for tests
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDownAll(() {
    SecurityUtils.defaultIterations = SecurityUtils.targetIterations;
  });

  setUp(() async {
    // Create fresh in-memory database for each test
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
        options: OpenDatabaseOptions(
            version: 7,
            onCreate: (db, version) async {
              // Manually create the users table and activity_logs table for tests
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

              // Seed a test user
              final hash = SecurityUtils.hashPassword('password123');
              await db.insert('users', {
                'full_name': 'Test User',
                'username': 'testuser',
                'password_hash': hash,
                'role': 'cashier',
                'status': 'active',
                'created_at': DateTime.now().toIso8601String(),
              });
            }));
            
    DatabaseHelper.setMockDatabase(db);
    userRepository = UserRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('Account Lockout Tests', () {
    test('5 failed attempts → account locked', () async {
      for (int i = 0; i < 5; i++) {
        final result = await userRepository.login('testuser', 'wrongpassword');
        expect(result, isNull);
      }

      // Check the database directly to verify status
      final userMaps = await db.query('users', where: 'username = ?', whereArgs: ['testuser']);
      expect(userMaps.first['status'], equals('locked'));
      expect(userMaps.first['failed_login_count'], equals(5));
    });

    test('Attempt 6 on locked account keeps it locked and returns null', () async {
      // Fail 5 times
      for (int i = 0; i < 5; i++) {
        await userRepository.login('testuser', 'wrongpassword');
      }

      // 6th attempt (even with correct password, because account is locked)
      final result6 = await userRepository.login('testuser', 'password123');
      expect(result6, isNull);
    });

    test('Successful login resets failed login counter', () async {
      // Fail 3 times
      for (int i = 0; i < 3; i++) {
        await userRepository.login('testuser', 'wrongpassword');
      }

      // Login successfully
      final successResult = await userRepository.login('testuser', 'password123');
      expect(successResult, isNotNull);
      expect(successResult!['failed_login_count'], equals(0));
    });

    test('unlockUser() clears counter and resets status to active', () async {
      // Lock the account
      for (int i = 0; i < 5; i++) {
        await userRepository.login('testuser', 'wrongpassword');
      }

      // Unlock
      final usersBefore = await db.query('users', where: 'username = ?', whereArgs: ['testuser']);
      final userId = usersBefore.first['id'] as int;
      await userRepository.unlockUser(userId, 'Admin User');

      // Verify
      final usersAfter = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      expect(usersAfter.first['status'], equals('active'));
      expect(usersAfter.first['failed_login_count'], equals(0));
    });
  });
}
