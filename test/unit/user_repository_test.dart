import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late UserRepository userRepository;
  late Database db;

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
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
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
    SessionManager().setSession({'id': 1, 'username': 'testuser', 'role': 'admin', 'status': 'active'});
  });

  tearDown(() async {
    SessionManager().clearSession();
    await db.close();
  });

  group('UserRepository', () {
    test('login returns user on valid credentials', () async {
      final user = await userRepository.login('testuser', 'password123');
      expect(user, isNotNull);
      expect(user!['username'], equals('testuser'));
    });

    test('login returns null on wrong password', () async {
      final user = await userRepository.login('testuser', 'wrongpassword');
      expect(user, isNull);
    });

    test('login returns null for locked account', () async {
      for (int i = 0; i < 5; i++) {
        await userRepository.login('testuser', 'wrong');
      }
      final user = await userRepository.login('testuser', 'password123');
      expect(user, isNull);
    });

    test('login returns null for non-existent user', () async {
      final user = await userRepository.login('nobody', 'password123');
      expect(user, isNull);
    });

    test('login resets failed_login_count on success', () async {
      await userRepository.login('testuser', 'wrong');
      await userRepository.login('testuser', 'password123');
      final users = await db.query('users', where: 'username = ?', whereArgs: ['testuser']);
      expect(users.first['failed_login_count'], equals(0));
    });

    test('getUser works', () async {
      final users = await userRepository.getAllUsers();
      expect(users.isNotEmpty, isTrue);
      expect(users.first['id'], equals(1));
    });

    test('getAllUsers returns list of users', () async {
      final users = await userRepository.getAllUsers();
      expect(users.length, equals(1));
    });

    test('updateUser updates user fields', () async {
      await userRepository.updateUser(1, {'full_name': 'Updated Name', 'role': 'admin'});
      final users = await db.query('users', where: 'id = ?', whereArgs: [1]);
      final user = users.first;
      expect(user['full_name'], equals('Updated Name'));
      expect(user['role'], equals('admin'));
    });

    test('changePassword works', () async {
      await userRepository.changePassword(1, 'newpassword123');
      
      final failedLogin = await userRepository.login('testuser', 'password123');
      expect(failedLogin, isNull);
      
      final successLogin = await userRepository.login('testuser', 'newpassword123');
      expect(successLogin, isNotNull);
    });
  });
}
