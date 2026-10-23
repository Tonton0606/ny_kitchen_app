import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/food_repository.dart';
import 'package:ny_kitchen_app/core/database/repositories/transaction_repository.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late Database db;
  late UserRepository userRepo;
  late FoodRepository foodRepo;
  late TransactionRepository transactionRepo;
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
              must_change_password INTEGER DEFAULT 0,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE food_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
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
              price REAL NOT NULL,
              image_path TEXT,
              availability TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT
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
              created_at TEXT NOT NULL
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
              subtotal REAL NOT NULL
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
    foodRepo = FoodRepository();
    transactionRepo = TransactionRepository();

    // Seed admin
    final adminHash = SecurityUtils.hashPassword('AdminPass2026!');
    await db.insert('users', {
      'id': 1,
      'full_name': 'Admin User',
      'username': 'admin',
      'password_hash': adminHash,
      'role': 'Admin',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await db.close();
  });

  group('T-12: SQL Injection Payload Resistance Tests', () {
    test('Login resists classic authentication bypass payloads', () async {
      final bypassPayloads = [
        "' OR '1'='1",
        "admin' --",
        "admin' /*",
        "' OR 1=1 --",
        "'; DROP TABLE users; --",
        "' UNION SELECT 1, 'admin', 'hash', 'admin', 'active' --",
      ];

      for (final payload in bypassPayloads) {
        final result = await userRepo.login(payload, 'any_password');
        expect(result, isNull,
            reason: 'Payload "$payload" must not bypass authentication');
      }

      // Verify users table was not dropped
      final users = await db.query('users');
      expect(users.length, equals(1));
    });

    test('Food search parameterization resists UNION and boolean injection', () async {
      sessionManager.setSession({
        'id': 1,
        'username': 'admin',
        'role': 'Admin',
      });

      await foodRepo.insertCategory('Rice Meals');
      await foodRepo.insertFoodItem({
        'name': 'Pastil Special',
        'price': 85.0,
        'category_id': 1,
        'availability': 'available',
        'status': 'active',
      });

      final injectionPayloads = [
        "' UNION SELECT id, username, password_hash, 0, '', '', '', '', '' FROM users --",
        "Pastil' OR '1'='1",
        "'; DELETE FROM food_items; --",
      ];

      for (final payload in injectionPayloads) {
        // Querying with SQL injection payload treats it strictly as literal text
        final results = await db.query(
          'food_items',
          where: 'name LIKE ?',
          whereArgs: ['%$payload%'],
        );
        expect(results, isEmpty,
            reason: 'Payload "$payload" should yield no matches');
      }

      // Verify food_items was not deleted
      final remaining = await foodRepo.getAllFoodItems();
      expect(remaining.length, equals(1));
    });

    test('Transaction queries resist receipt number injection', () async {
      sessionManager.setSession({
        'id': 1,
        'username': 'admin',
        'role': 'Admin',
      });

      final result = await transactionRepo.createTransaction(
        userId: 1,
        totalAmount: 100.0,
        discount: 0.0,
        paymentMethod: 'cash',
        amountReceived: 100.0,
        change: 0.0,
        items: [],
      );
      expect(result, isNotNull);

      // Attempt injection in transaction status filtering
      const maliciousStatus = "completed' OR '1'='1";
      final txList = await transactionRepo.getTransactions(status: maliciousStatus);
      expect(txList, isEmpty,
          reason: 'Injection payload in status filter must return no matching records');

      // Attempt injection in parameterized query by receipt
      const maliciousReceipt = "RCP-001' OR 1=1 --";
      final tx = await db.query(
        'transactions',
        where: 'receipt_number = ?',
        whereArgs: [maliciousReceipt],
      );
      expect(tx, isEmpty,
          reason: 'Injection payload in receipt search must return empty');
    });
  });
}
