import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
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
              metadata TEXT,
              timestamp TEXT NOT NULL
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

  group('B1 - Transparent Password Re-Hash on Login', () {
    test('User with legacy 10,000 iteration hash is transparently upgraded to 600,000 on login', () async {
      const username = 'cashier_legacy';
      const password = 'Password123!';
      const legacySalt = 'LegacySalt123=';

      // Manually construct legacy 2-part hash: salt:hash (10,000 iterations)
      // We can use hashPassword with 10,000 and strip the iteration prefix
      final rawHash = SecurityUtils.hashPassword(password, legacySalt, 10000);
      final rawParts = rawHash.split(':');
      final legacyStoredHash = '${rawParts[1]}:${rawParts[2]}'; // 'salt:hash' (2 parts)

      expect(SecurityUtils.needsRehash(legacyStoredHash), isTrue,
          reason: 'Legacy 2-part hash must require re-hash');

      final now = DateTime.now().toIso8601String();
      await db.insert('users', {
        'full_name': 'Legacy Cashier',
        'username': username,
        'password_hash': legacyStoredHash,
        'role': 'cashier',
        'status': 'active',
        'must_change_password': 0,
        'created_at': now,
      });

      // 1. Perform login with legacy password
      final loggedInUser = await userRepository.login(username, password);
      expect(loggedInUser, isNotNull, reason: 'Login must succeed with legacy password hash');
      expect(loggedInUser!['username'], equals(username));

      // 2. Fetch updated user directly from SQLite
      final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
      expect(rows.length, equals(1));
      final upgradedHash = rows.first['password_hash'] as String;

      // 3. Verify format has been upgraded to 3 parts with 600,000 iterations
      final parts = upgradedHash.split(':');
      expect(parts.length, equals(3), reason: 'Upgraded hash must be iterations:salt:hash');
      expect(int.parse(parts[0]), equals(600000),
          reason: 'Iteration count must be upgraded to 600,000');
      expect(SecurityUtils.needsRehash(upgradedHash), isFalse,
          reason: 'Upgraded hash must no longer need re-hash');

      // 4. Verify that subsequent login succeeds against the upgraded hash
      final subsequentLogin = await userRepository.login(username, password);
      expect(subsequentLogin, isNotNull);
      expect(subsequentLogin!['username'], equals(username));
    });
  });
}
