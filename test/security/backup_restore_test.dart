import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/backup_repository.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:ny_kitchen_app/core/utils/security_exception.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

void main() {
  late Database db;
  late BackupRepository backupRepo;
  late Directory tempDir;

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
    tempDir = await Directory.systemTemp.createTemp('ny_kitchen_backup_test_');

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
              face_encoding TEXT,
              must_change_password INTEGER DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE food_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT UNIQUE NOT NULL,
              icon_url TEXT,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE food_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER,
              name TEXT NOT NULL,
              description TEXT,
              price REAL NOT NULL,
              image_path TEXT,
              availability TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT,
              FOREIGN KEY (category_id) REFERENCES food_categories (id) ON DELETE SET NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              receipt_number TEXT UNIQUE NOT NULL,
              order_number INTEGER,
              user_id INTEGER,
              total_amount REAL NOT NULL,
              discount REAL DEFAULT 0,
              payment_method TEXT NOT NULL,
              amount_received REAL,
              change REAL,
              status TEXT NOT NULL,
              void_reason TEXT,
              refund_reason TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE transaction_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              transaction_id INTEGER NOT NULL,
              food_item_id INTEGER,
              food_name TEXT NOT NULL,
              food_price REAL NOT NULL,
              quantity INTEGER NOT NULL,
              subtotal REAL NOT NULL,
              FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
              FOREIGN KEY (food_item_id) REFERENCES food_items (id) ON DELETE SET NULL
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
          await db.execute('''
            CREATE TABLE login_attempts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT NOT NULL,
              status TEXT NOT NULL,
              ip_address TEXT,
              device_info TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE backup_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              filename TEXT NOT NULL,
              file_path TEXT NOT NULL,
              file_size INTEGER NOT NULL,
              created_by INTEGER,
              created_at TEXT NOT NULL,
              FOREIGN KEY (created_by) REFERENCES users (id) ON DELETE SET NULL
            )
          ''');
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    backupRepo = BackupRepository();

    // Seed baseline admin & category
    await db.insert('users', {
      'id': 1,
      'full_name': 'Admin User',
      'username': 'admin',
      'password_hash': SecurityUtils.hashPassword('admin1234'),
      'role': 'admin',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('food_categories', {
      'id': 1,
      'name': 'Meals',
      'icon_url': '🍚',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('food_items', {
      'id': 1,
      'category_id': 1,
      'name': 'Original Burger',
      'price': 120.0,
      'availability': 'available',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });

    SessionManager().clearSession();
  });

  tearDown(() async {
    SessionManager().clearSession();
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Backup & Restore Security & Defense Tests', () {
    test('Non-authenticated caller cannot restore database (SEC-01 / SEC-03)', () async {
      final fakeFile = File(p.join(tempDir.path, 'backup.sql'));
      await fakeFile.writeAsString('INSERT INTO users VALUES (1);');

      await expectLater(
        backupRepo.restoreDatabase(fakeFile),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
    });

    test('Non-admin role (Cashier) is forbidden from restoring database (SEC-01 / SEC-03)', () async {
      SessionManager().setSession({
        'id': 2,
        'username': 'cashier',
        'role': 'cashier',
        'status': 'active',
      });

      final fakeFile = File(p.join(tempDir.path, 'backup.sql'));
      await fakeFile.writeAsString('INSERT INTO users VALUES (1);');

      await expectLater(
        backupRepo.restoreDatabase(fakeFile),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'FORBIDDEN_ROLE')),
      );
    });

    test('Missing backup file is rejected with INVALID_BACKUP_FILE', () async {
      SessionManager().setSession({
        'id': 1,
        'username': 'admin',
        'role': 'admin',
        'status': 'active',
      });

      final missingFile = File(p.join(tempDir.path, 'does_not_exist.sql'));

      await expectLater(
        backupRepo.restoreDatabase(missingFile),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'INVALID_BACKUP_FILE')),
      );
    });

    test('Empty backup file (0 bytes) is rejected with INVALID_BACKUP_FILE', () async {
      SessionManager().setSession({
        'id': 1,
        'username': 'admin',
        'role': 'admin',
        'status': 'active',
      });

      final emptyFile = File(p.join(tempDir.path, 'empty.sql'));
      await emptyFile.create();

      await expectLater(
        backupRepo.restoreDatabase(emptyFile),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'INVALID_BACKUP_FILE')),
      );
    });

    test('Disallowed file extension is rejected with INVALID_BACKUP_FILE', () async {
      SessionManager().setSession({
        'id': 1,
        'username': 'admin',
        'role': 'admin',
        'status': 'active',
      });

      final txtFile = File(p.join(tempDir.path, 'backup.txt'));
      await txtFile.writeAsString('INSERT INTO users VALUES (1);');

      await expectLater(
        backupRepo.restoreDatabase(txtFile),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'INVALID_BACKUP_FILE')),
      );
    });

    test('Malicious SQL (DROP TABLE) is detected and blocked with UNAUTHORIZED_SQL_STATEMENT', () async {
      SessionManager().setSession({
        'id': 1,
        'username': 'admin',
        'role': 'admin',
        'status': 'active',
      });

      final maliciousFile = File(p.join(tempDir.path, 'malicious.sql'));
      await maliciousFile.writeAsString('DROP TABLE users;\nINSERT INTO users VALUES (1);');

      await expectLater(
        backupRepo.restoreDatabase(maliciousFile),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHORIZED_SQL_STATEMENT')),
      );

      // Verify users table still exists and data is intact
      final users = await db.query('users');
      expect(users.isNotEmpty, isTrue);
    });

    test('SQL inserting into unapproved table is rejected with UNAUTHORIZED_TABLE', () async {
      SessionManager().setSession({
        'id': 1,
        'username': 'admin',
        'role': 'admin',
        'status': 'active',
      });

      final unapprovedTableFile = File(p.join(tempDir.path, 'unapproved.sql'));
      await unapprovedTableFile.writeAsString('INSERT INTO evil_table (id) VALUES (1);');

      await expectLater(
        backupRepo.restoreDatabase(unapprovedTableFile),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHORIZED_TABLE')),
      );
    });

    test('Valid SQL dump restores database state and records audit log', () async {
      SessionManager().setSession({
        'id': 1,
        'username': 'admin',
        'role': 'admin',
        'status': 'active',
      });

      final now = DateTime.now().toIso8601String();
      final validSql = '''
-- NY Kitchen Database Backup Test
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
INSERT INTO `food_categories` (`id`, `name`, `icon_url`, `status`, `created_at`) VALUES (2, 'Beverages', '🥤', 'active', '$now');
INSERT INTO `food_items` (`id`, `category_id`, `name`, `price`, `availability`, `status`, `created_at`) VALUES (10, 2, 'Iced Tea', 45.0, 'available', 'active', '$now');
INSERT INTO `users` (`id`, `full_name`, `username`, `password_hash`, `role`, `status`, `created_at`) VALUES (1, 'Admin Restored', 'admin', 'hash123', 'admin', 'active', '$now');
COMMIT;
''';

      final sqlFile = File(p.join(tempDir.path, 'valid_backup.sql'));
      await sqlFile.writeAsString(validSql);

      final success = await backupRepo.restoreDatabase(sqlFile);
      expect(success, isTrue);

      // Verify food_items now contains the restored item
      final foodItems = await db.query('food_items');
      expect(foodItems.length, equals(1));
      expect(foodItems.first['name'], equals('Iced Tea'));
      expect(foodItems.first['price'], equals(45.0));

      // Verify activity log was recorded
      final logs = await db.query(
        'activity_logs',
        where: 'module = ? AND action = ?',
        whereArgs: ['Backup & Restore', 'Database Restored'],
      );
      expect(logs.isNotEmpty, isTrue);
      expect(logs.first['status'], equals('Success'));
    });

    test('Corrupted SQL statement triggers atomic rollback leaving data intact (AT08)', () async {
      SessionManager().setSession({
        'id': 1,
        'username': 'admin',
        'role': 'admin',
        'status': 'active',
      });

      // Verify baseline item
      final beforeFood = await db.query('food_items');
      expect(beforeFood.length, equals(1));
      expect(beforeFood.first['name'], equals('Original Burger'));

      // This backup contains a valid insert followed by a malformed statement that fails execution
      final corruptedSql = '''
INSERT INTO `food_categories` (`id`, `name`, `icon_url`, `status`, `created_at`) VALUES (3, 'Pasta', '🍝', 'active', '2026-10-23');
INSERT INTO `food_items` (`id`, `invalid_column_that_does_not_exist`) VALUES (99);
''';

      final corruptedFile = File(p.join(tempDir.path, 'corrupted_exec.sql'));
      await corruptedFile.writeAsString(corruptedSql);

      await expectLater(
        backupRepo.restoreDatabase(corruptedFile),
        throwsA(anything),
      );

      // Verify atomic rollback preserved original data
      final afterFood = await db.query('food_items');
      expect(afterFood.length, equals(1));
      expect(afterFood.first['name'], equals('Original Burger'));
    });
  });
}
