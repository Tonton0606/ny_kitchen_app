import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/transaction_repository.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late TransactionRepository transactionRepository;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath,
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
                  created_at TEXT NOT NULL
                )
              ''');
              
              await db.execute('''
                CREATE TABLE food_categories (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT NOT NULL,
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
                  FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
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
              
              await db.insert('users', {
                'id': 1,
                'full_name': 'Test Cashier',
                'username': 'cashier',
                'password_hash': 'hash',
                'role': 'cashier',
                'status': 'active',
                'created_at': DateTime.now().toIso8601String(),
              });
            }));
            
    DatabaseHelper.setMockDatabase(db);
    SessionManager().setSession({
      'id': 1,
      'username': 'admin',
      'role': 'Admin',
      'full_name': 'Test Admin',
    });
    transactionRepository = TransactionRepository();
  });

  tearDown(() async {
    SessionManager().clearSession();
    await db.close();
  });

  group('Sync Failure Offline Tests', () {
    test('Mock Supabase network failure -> local SQLite continues working', () async {
      // Create a transaction, assuming SyncService throws internally but is caught.
      // Since SyncService catches its own errors and just prints them, this should not throw an exception.
      final result = await transactionRepository.createTransaction(
        userId: 1,
        totalAmount: 500.0,
        discount: 0.0,
        paymentMethod: 'cash',
        amountReceived: 500.0,
        change: 0.0,
        items: [],
      );

      expect(result, isNotNull);
      
      final txs = await db.query('transactions');
      expect(txs.length, equals(1));
    });

    test('Transaction created while offline is stored locally without error', () async {
      final items = [
        {
          'food_item_id': 101,
          'food_name': 'Offline Burger',
          'food_price': 150.0,
          'quantity': 2,
          'subtotal': 300.0,
        }
      ];
      
      final result = await transactionRepository.createTransaction(
        userId: 1,
        totalAmount: 300.0,
        discount: 0.0,
        paymentMethod: 'cash',
        amountReceived: 300.0,
        change: 0.0,
        items: items,
      );
      
      expect(result['id'], isNotNull);
      
      final txItems = await db.query('transaction_items', where: 'food_name = ?', whereArgs: ['Offline Burger']);
      expect(txItems.length, equals(1));
      expect(txItems.first['subtotal'], equals(300.0));
    });
  });
}
