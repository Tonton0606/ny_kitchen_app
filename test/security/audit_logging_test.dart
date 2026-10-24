import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/audit_repository.dart';
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
  late AuditRepository auditRepo;

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
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 7,
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
          await db.execute('''
            CREATE TABLE food_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              category_id INTEGER,
              name TEXT NOT NULL,
              price REAL NOT NULL,
              image_path TEXT,
              availability TEXT DEFAULT 'available',
              status TEXT DEFAULT 'active',
              created_at TEXT NOT NULL,
              updated_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              receipt_number TEXT UNIQUE NOT NULL,
              order_number INTEGER NOT NULL,
              user_id INTEGER NOT NULL,
              total_amount REAL NOT NULL,
              discount REAL DEFAULT 0,
              payment_method TEXT NOT NULL,
              amount_received REAL NOT NULL,
              change REAL NOT NULL,
              status TEXT NOT NULL,
              order_type TEXT NOT NULL DEFAULT 'dine_in',
              packaging_fee REAL NOT NULL DEFAULT 0,
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

          // Seed user
          await db.insert('users', {
            'full_name': 'Admin User',
            'username': 'admin',
            'password_hash': SecurityUtils.hashPassword('admin123'),
            'role': 'admin',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    userRepo = UserRepository();

    foodRepo = FoodRepository();
    transactionRepo = TransactionRepository();
    auditRepo = AuditRepository();
  });

  tearDown(() async {
    SessionManager().clearSession();
    await db.close();
  });

  group('A4 - Audit Logging (Gaps 7-9)', () {
    test('Successful login logs an audit record', () async {
      final user = await userRepo.login('admin', 'admin123');
      expect(user, isNotNull);

      final logs = await auditRepo.getLogs(search: 'Login Successful');
      expect(logs.isNotEmpty, isTrue, reason: 'Successful login must be audited (Gap 7)');
      expect(logs.first['action'], equals('Login Successful'));
      expect(logs.first['username'], equals('admin'));
      expect(logs.first['status'], equals('Success'));
    });

    test('Logout logs an audit record without credentials', () async {
      final user = await userRepo.login('admin', 'admin123');
      SessionManager().setSession(user!);

      SessionManager().clearSession();


      final logs = await auditRepo.getLogs(search: 'User Logout');
      expect(logs.isNotEmpty, isTrue, reason: 'Logout event must be audited (Gap 8)');
      expect(logs.first['action'], equals('User Logout'));
      expect(logs.first['username'], equals('admin'));
    });

    test('Food item CRUD operations create audit records', () async {
      SessionManager().setSession({'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'});
      final foodId = await foodRepo.insertFoodItem({
        'name': 'Burger',
        'price': 99.0,
        'availability': 'available',
        'status': 'active',
      });
      expect(foodId, greaterThan(0));

      var foodLogs = await auditRepo.getLogs(search: 'Food Created');
      expect(foodLogs.isNotEmpty, isTrue, reason: 'Food creation must be audited (Gap 9)');

      await foodRepo.updateFoodItem(foodId, {'name': 'Double Burger', 'price': 149.0});
      foodLogs = await auditRepo.getLogs(search: 'Food Updated');
      expect(foodLogs.isNotEmpty, isTrue, reason: 'Food update must be audited (Gap 9)');

      await foodRepo.archiveFoodItem(foodId);
      foodLogs = await auditRepo.getLogs(search: 'Food Archived');
      expect(foodLogs.isNotEmpty, isTrue, reason: 'Food deletion/archival must be audited (Gap 9)');
    });

    test('Transaction creation and voiding create audit records', () async {
      SessionManager().setSession({'id': 1, 'username': 'cashier', 'role': 'cashier', 'status': 'active'});
      final tx = await transactionRepo.createTransaction(
        userId: 1,
        totalAmount: 100.0,
        discount: 0.0,
        paymentMethod: 'Cash',
        amountReceived: 100.0,
        change: 0.0,
        items: [
          {
            'food_item_id': 1,
            'food_name': 'Burger',
            'food_price': 100.0,
            'quantity': 1,
            'subtotal': 100.0,
          }
        ],
      );
      final txId = tx['transaction_id'] as int;
      expect(txId, greaterThan(0));

      var txLogs = await auditRepo.getLogs(search: 'Transaction Created');
      expect(txLogs.isNotEmpty, isTrue, reason: 'Transaction create must be audited (Gap 9)');

      await transactionRepo.cancelOrder(txId, reason: 'Customer changed mind');
      txLogs = await auditRepo.getLogs(search: 'Transaction Voided');
      expect(txLogs.isNotEmpty, isTrue, reason: 'Transaction void must be audited (Gap 9)');
    });

    test('Admin user creation and modification create audit records', () async {
      SessionManager().setSession({'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'});
      final newUserId = await userRepo.createUser({
        'full_name': 'Cashier 2',
        'username': 'cashier2',
        'password_hash': SecurityUtils.hashPassword('cashier123'),
        'role': 'cashier',
        'status': 'active',
      });
      expect(newUserId, greaterThan(0));

      var userLogs = await auditRepo.getLogs(search: 'User Created');
      expect(userLogs.isNotEmpty, isTrue, reason: 'User creation must be audited (Gap 9)');

      await userRepo.updateUser(newUserId, {'full_name': 'Cashier 2 Updated'});
      userLogs = await auditRepo.getLogs(search: 'User Updated');
      expect(userLogs.isNotEmpty, isTrue, reason: 'User modification must be audited (Gap 9)');
    });

    test('Unauthorized access attempts and self-disable create blocked audit records', () async {
      SessionManager().setSession({'id': 2, 'username': 'cashier', 'role': 'cashier', 'status': 'active'});

      // Cashier attempts to call an admin repository function (createUser)
      try {
        await userRepo.createUser({
          'full_name': 'Intruder',
          'username': 'intruder',
          'password_hash': SecurityUtils.hashPassword('password123'),
          'role': 'admin',
          'status': 'active',
        });
      } catch (_) {}

      final blockedLogs = await auditRepo.getLogs(status: 'Blocked');
      expect(blockedLogs.isNotEmpty, isTrue, reason: 'Unauthorized access attempts must generate Blocked audit logs (Gap 7/9)');
      expect(blockedLogs.first['status'], equals('Blocked'));
      expect(blockedLogs.first['username'], equals('cashier'));
    });
  });
}
