import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/security_utils.dart';

class DatabaseHelper {
  static const _databaseName = "ny_kitchen.db";
  static const _databaseVersion = 9;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Allows injecting an in-memory database for testing
  static void setMockDatabase(Database mockDb) {
    _database = mockDb;
  }

  static Future<String> getDatabasePath() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    return join(documentsDirectory.path, _databaseName);
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    
    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );

    // Normalize legacy mock transaction statuses to 'Served' or 'Preparing'
    try {
      await db.rawUpdate(
        "UPDATE transactions SET status = 'Served' WHERE status IN ('Taken', 'Ready', 'Completed', 'completed')",
      );
      await db.rawUpdate(
        "UPDATE transactions SET status = 'Preparing' WHERE status = 'preparing'",
      );
    } catch (_) {}

    return db;
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final now = DateTime.now().toIso8601String();
      await db.update(
        'users',
        {'password_hash': SecurityUtils.hashPassword('admin123')},
        where: 'username = ?',
        whereArgs: ['admin'],
      );
      final maps = await db.query('users', where: 'username = ?', whereArgs: ['cashier']);
      if (maps.isEmpty) {
        await db.insert('users', {
          'full_name': 'Head Cashier',
          'username': 'cashier',
          'password_hash': SecurityUtils.hashPassword('cashier123'),
          'role': 'cashier',
          'status': 'active',
          'created_at': now,
        });
      }
    }
    if (oldVersion < 3) {
      // Add icon_url column to food_categories
      try {
        await db.execute('ALTER TABLE food_categories ADD COLUMN icon_url TEXT');
      } catch (_) {}
      // Seed default icon_urls for known categories
      final categoryIcons = {
        'Rice Meals': '🍚',
        'Snacks': '🍡',
        'Pasta': '🍝',
        'Beverages': '🥤',
        'Desserts': '🍨',
        'Specials': '⭐',
      };
      for (final entry in categoryIcons.entries) {
        await db.update(
          'food_categories',
          {'icon_url': entry.value},
          where: 'name = ? AND (icon_url IS NULL OR icon_url = \'\')',
          whereArgs: [entry.key],
        );
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE food_categories ADD COLUMN updated_at TEXT');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN amount_received REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN change REAL');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN order_number INTEGER');
      } catch (_) {}
    }

    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN must_change_password INTEGER DEFAULT 0');
      } catch (_) {}
      // Flag seeded default accounts to force password change (Gap 3)
      try {
        await db.update(
          'users',
          {'must_change_password': 1},
          where: 'username IN (?, ?)',
          whereArgs: ['admin', 'cashier'],
        );
      } catch (_) {}
    }

    if (oldVersion < 9) {
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN order_type TEXT NOT NULL DEFAULT 'dine_in'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE transactions ADD COLUMN packaging_fee REAL NOT NULL DEFAULT 0");
      } catch (_) {}
    }
  }

  Future _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    // 1. users
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

    // 2. food_categories
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

    // 3. food_items
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

    // 4. transactions
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_number TEXT UNIQUE NOT NULL,
        order_number INTEGER,
        user_id INTEGER,
        order_type TEXT NOT NULL DEFAULT 'dine_in',
        packaging_fee REAL NOT NULL DEFAULT 0,
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

    // 5. transaction_items
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

    // 6. activity_logs
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

    // 7. login_attempts
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

    // 8. app_settings
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 9. backup_records
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

    // Seed default admin account
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();
    // Default admin
    await db.insert('users', {
      'full_name': 'System Administrator',
      'username': 'admin',
      'password_hash': SecurityUtils.hashPassword('admin123'),
      'role': 'admin',
      'status': 'active',
      'must_change_password': 1,
      'created_at': now,
    });

    // Default cashier
    await db.insert('users', {
      'full_name': 'Head Cashier',
      'username': 'cashier',
      'password_hash': SecurityUtils.hashPassword('cashier123'),
      'role': 'cashier',
      'status': 'active',
      'must_change_password': 1,
      'created_at': now,
    });

    // Seed Food Categories with default emoji icons
    final categories = [
      {'name': 'Rice Meals', 'icon_url': '🍚'},
      {'name': 'Snacks',     'icon_url': '🍡'},
      {'name': 'Pasta',      'icon_url': '🍝'},
      {'name': 'Beverages',  'icon_url': '🥤'},
      {'name': 'Desserts',   'icon_url': '🍨'},
      {'name': 'Specials',   'icon_url': '⭐'},
    ];
    for (var cat in categories) {
      await db.insert('food_categories', {
        'name': cat['name'],
        'icon_url': cat['icon_url'],
        'status': 'active',
        'created_at': now,
      });
    }

    // Seed Food Items
    final foods = [
      {'name': 'Chicken Adobo', 'category_id': 1, 'price': 120.0, 'image_path': 'https://placehold.co/300x200/FFCA05/2B241A?text=Adobo&font=raleway'},
      {'name': 'Pork Sisig', 'category_id': 1, 'price': 150.0, 'image_path': 'https://placehold.co/300x200/FFCA05/2B241A?text=Sisig&font=raleway'},
      {'name': 'Beef Tapa', 'category_id': 1, 'price': 140.0, 'image_path': 'https://placehold.co/300x200/FFCA05/2B241A?text=Tapa&font=raleway'},
      {'name': 'Lumpia', 'category_id': 2, 'price': 50.0, 'image_path': 'https://placehold.co/300x200/FFCA05/2B241A?text=Lumpia&font=raleway'},
      {'name': 'Halo-Halo', 'category_id': 5, 'price': 80.0, 'image_path': 'https://placehold.co/300x200/FFCA05/2B241A?text=Halo-Halo&font=raleway'},
      {'name': 'Pancit Canton', 'category_id': 3, 'price': 100.0, 'image_path': 'https://placehold.co/300x200/FFCA05/2B241A?text=Pancit&font=raleway'},
    ];

    for (var f in foods) {
      await db.insert('food_items', {
        'category_id': f['category_id'],
        'name': f['name'],
        'price': f['price'],
        'image_path': f['image_path'],
        'availability': 'available',
        'status': 'active',
        'created_at': now,
      });
    }
  }
}
