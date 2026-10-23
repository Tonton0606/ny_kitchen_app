import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/database/repositories/food_repository.dart';
import 'package:ny_kitchen_app/core/database/repositories/transaction_repository.dart';
import 'package:ny_kitchen_app/core/database/repositories/backup_repository.dart';
import 'package:ny_kitchen_app/core/database/repositories/audit_repository.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:ny_kitchen_app/core/utils/security_exception.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  late Database db;
  late UserRepository userRepo;
  late FoodRepository foodRepo;
  late TransactionRepository transactionRepo;
  late BackupRepository backupRepo;
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
              name TEXT NOT NULL,
              icon_url TEXT,
              status TEXT NOT NULL DEFAULT 'active',
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
              availability TEXT NOT NULL,
              image_path TEXT,
              status TEXT NOT NULL DEFAULT 'active',
              created_at TEXT NOT NULL,
              updated_at TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              receipt_number TEXT UNIQUE,
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
            CREATE TABLE app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          // Seed default admin and cashier
          await db.insert('users', {
            'id': 1,
            'full_name': 'System Administrator',
            'username': 'admin',
            'password_hash': SecurityUtils.hashPassword('admin1234'),
            'role': 'admin',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
          await db.insert('users', {
            'id': 2,
            'full_name': 'Primary Cashier',
            'username': 'cashier',
            'password_hash': SecurityUtils.hashPassword('cashier1234'),
            'role': 'cashier',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
          await db.insert('users', {
            'id': 3,
            'full_name': 'Secondary Cashier',
            'username': 'cashier2',
            'password_hash': SecurityUtils.hashPassword('cashier1234'),
            'role': 'cashier',
            'status': 'active',
            'created_at': DateTime.now().toIso8601String(),
          });
          await db.insert('food_items', {
            'id': 1,
            'name': 'Original Burger',
            'price': 120.0,
            'availability': 'available',
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
    backupRepo = BackupRepository();
    auditRepo = AuditRepository();
    SessionManager().clearSession();
  });

  tearDown(() async {
    SessionManager().clearSession();
    await db.close();
  });

  group('AT02 & SEC-01: Repository-Level Authorization Enforcement', () {
    test('Unauthenticated caller is rejected with SecurityException for all privileged mutations', () async {
      // 1. User mutations
      await expectLater(
        userRepo.getAllUsers(),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
      await expectLater(
        userRepo.createUser({'username': 'newuser', 'role': 'cashier'}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
      await expectLater(
        userRepo.updateUser(2, {'full_name': 'Hacked'}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
      await expectLater(
        userRepo.disableUser(2),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );

      // 2. Food mutations
      await expectLater(
        foodRepo.getAllFoodItems(),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
      await expectLater(
        foodRepo.insertFoodItem({'name': 'Tacos', 'price': 80.0}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
      await expectLater(
        foodRepo.updateFoodItem(1, {'price': 1.0}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );

      // 3. Transactions & Backups
      await expectLater(
        transactionRepo.createTransaction(
          userId: 1,
          totalAmount: 100,
          discount: 0,
          paymentMethod: 'Cash',
          amountReceived: 100,
          change: 0,
          items: [],
        ),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );
      await expectLater(
        backupRepo.exportDatabase(),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'UNAUTHENTICATED')),
      );

      // Verify that unauthenticated denials were audited
      final blockedLogs = await db.query('activity_logs', where: "status = 'Blocked'");
      expect(blockedLogs.isNotEmpty, isTrue);
    });

    test('Expired session caller is rejected with SESSION_EXPIRED', () async {
      SessionManager().setSession({'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'});
      SessionManager().lastActive = DateTime.now().subtract(const Duration(minutes: 31)); // Expired

      await expectLater(
        foodRepo.insertFoodItem({'name': 'Salad', 'price': 75.0}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'SESSION_EXPIRED')),
      );
    });

    test('Cashier is blocked from Admin operations with FORBIDDEN_ROLE and zero mutations occur', () async {
      SessionManager().setSession({'id': 2, 'username': 'cashier', 'role': 'cashier', 'status': 'active'});

      // Attempt to view all users
      await expectLater(
        userRepo.getAllUsers(),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'FORBIDDEN_ROLE')),
      );

      // Attempt to create user
      await expectLater(
        userRepo.createUser({'username': 'backdoor', 'role': 'admin'}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'FORBIDDEN_ROLE')),
      );

      // Attempt to modify food menu prices
      await expectLater(
        foodRepo.updateFoodItem(1, {'price': 1.0}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'FORBIDDEN_ROLE')),
      );

      // Attempt to export backup
      await expectLater(
        backupRepo.exportDatabase(),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'FORBIDDEN_ROLE')),
      );

      // Verify zero mutations occurred
      final foodRows = await db.query('food_items', where: 'id = ?', whereArgs: [1]);
      expect(foodRows.first['price'], equals(120.0), reason: 'Price must remain unchanged by unauthorized call');
      final backdoorUsers = await db.query('users', where: 'username = ?', whereArgs: ['backdoor']);
      expect(backdoorUsers, isEmpty, reason: 'Unauthorized user creation must be blocked');
    });

    test('Transaction creation binds to authentic session actor and prevents userId spoofing', () async {
      // Logged in as cashier (id: 2)
      SessionManager().setSession({'id': 2, 'username': 'cashier', 'role': 'cashier', 'status': 'active'});

      // Caller attempts to spoof userId: 999 (admin impersonation)
      final tx = await transactionRepo.createTransaction(
        userId: 999, // Spoofed ID
        totalAmount: 150.0,
        discount: 0.0,
        paymentMethod: 'Cash',
        amountReceived: 200.0,
        change: 50.0,
        items: [
          {
            'food_item_id': 1,
            'food_name': 'Original Burger',
            'food_price': 120.0,
            'quantity': 1,
            'subtotal': 120.0,
          }
        ],
      );

      final txId = tx['transaction_id'] as int;
      final savedTx = await db.query('transactions', where: 'id = ?', whereArgs: [txId]);
      expect(savedTx.first['user_id'], equals(2), reason: 'Transaction must bind to real authenticated session (ID 2)');
    });

    test('Own-record access restrictions: Cashier can edit own profile but is blocked from others', () async {
      SessionManager().setSession({'id': 2, 'username': 'cashier', 'role': 'cashier', 'status': 'active'});

      // 1. Edit own profile succeeds
      final ownUpdate = await userRepo.updateUser(2, {'full_name': 'Updated Cashier Name'});
      expect(ownUpdate, equals(1));

      // 2. Attempt to edit another user's profile (user ID 3) fails
      await expectLater(
        userRepo.updateUser(3, {'full_name': 'Malicious Edit'}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'FORBIDDEN_OWN_RECORD')),
      );

      // 3. Attempt to elevate own role to 'admin' is blocked
      await expectLater(
        userRepo.updateUser(2, {'role': 'admin'}),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'FORBIDDEN_ROLE')),
      );

      // 4. Cashier can view food menu catalog (getAllFoodItems) to take orders
      final cashierFoods = await foodRepo.getAllFoodItems();
      expect(cashierFoods.isNotEmpty, isTrue);

      // 5. Cashier calling getAllTransactions only receives their own transactions
      await db.insert('transactions', {
        'receipt_number': 'TX-CASHIER-2',
        'user_id': 2,
        'total_amount': 250.0,
        'payment_method': 'Cash',
        'status': 'Served',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('transactions', {
        'receipt_number': 'TX-OTHER-3',
        'user_id': 3,
        'total_amount': 500.0,
        'payment_method': 'Cash',
        'status': 'Served',
        'created_at': DateTime.now().toIso8601String(),
      });
      final cashierTxns = await transactionRepo.getAllTransactions();
      expect(cashierTxns.every((t) => t['user_id'] == 2), isTrue,
          reason: 'Cashier must only see their own transactions');
    });

    test('Audit log querying restricts non-admins to their own user ID records', () async {
      // Create test logs for user 1 (admin) and user 2 (cashier)
      await auditRepo.logAction(
        userId: 1,
        username: 'admin',
        role: 'admin',
        module: 'Security',
        action: 'Admin Secret Action',
        status: 'Success',
      );
      await auditRepo.logAction(
        userId: 2,
        username: 'cashier',
        role: 'cashier',
        module: 'POS',
        action: 'Cashier Order Taken',
        status: 'Success',
      );

      // 1. Cashier queries logs - even without specifying userId, only cashier logs returned
      SessionManager().setSession({'id': 2, 'username': 'cashier', 'role': 'cashier', 'status': 'active'});
      final cashierLogs = await auditRepo.getLogs();
      expect(cashierLogs.every((l) => l['user_id'] == 2), isTrue);

      // 2. Admin queries logs - all records visible
      SessionManager().setSession({'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'});
      final adminLogs = await auditRepo.getLogs();
      expect(adminLogs.any((l) => l['user_id'] == 1), isTrue);
      expect(adminLogs.any((l) => l['user_id'] == 2), isTrue);
    });

    test('Password policy enforced at repository layer (SEC-05)', () async {
      SessionManager().setSession({'id': 2, 'username': 'cashier', 'role': 'cashier', 'status': 'active'});

      // Weak password rejected
      await expectLater(
        userRepo.changePassword(2, 'weak'),
        throwsA(isA<SecurityException>().having((e) => e.code, 'code', 'WEAK_PASSWORD')),
      );

      // Strong password accepted
      final success = await userRepo.changePassword(2, 'ValidPass1234');
      expect(success, isTrue);
    });

    test('Admin caller has full authorized access to administrative operations', () async {
      SessionManager().setSession({'id': 1, 'username': 'admin', 'role': 'admin', 'status': 'active'});

      // Create food item
      final foodId = await foodRepo.insertFoodItem({
        'name': 'Crispy Chicken',
        'price': 150.0,
        'availability': 'available',
        'status': 'active',
      });
      expect(foodId, greaterThan(0));

      // View all users
      final users = await userRepo.getAllUsers();
      expect(users.length, greaterThanOrEqualTo(3));

      // Create user
      final newUserId = await userRepo.createUser({
        'full_name': 'Third Cashier',
        'username': 'cashier3',
        'password_hash': SecurityUtils.hashPassword('cashier1234'),
        'role': 'cashier',
        'status': 'active',
      });
      expect(newUserId, greaterThan(0));

      // Disable user
      final disabledCount = await userRepo.disableUser(newUserId);
      expect(disabledCount, equals(1));
    });
  });
}
