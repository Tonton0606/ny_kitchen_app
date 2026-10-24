import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/food_repository.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late FoodRepository foodRepo;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              full_name TEXT NOT NULL,
              username TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              role TEXT NOT NULL,
              status TEXT NOT NULL,
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
            CREATE TABLE activity_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              username TEXT,
              role TEXT,
              module TEXT,
              action TEXT,
              status TEXT,
              description TEXT,
              timestamp TEXT
            )
          ''');
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    foodRepo = FoodRepository();

    // Seed test users
    await db.insert('users', {
      'id': 1,
      'full_name': 'Admin User',
      'username': 'admin',
      'password_hash': 'hash',
      'role': 'admin',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('users', {
      'id': 2,
      'full_name': 'Cashier User',
      'username': 'cashier',
      'password_hash': 'hash',
      'role': 'cashier',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed initial categories
    await db.insert('food_categories', {
      'id': 10,
      'name': 'Chicken Pastil Meals',
      'icon_url': 'drumstick',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
    await db.insert('food_categories', {
      'id': 19,
      'name': 'Burgersteak',
      'icon_url': 'cooking_pot',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Seed a food item in category 10
    await db.insert('food_items', {
      'id': 77,
      'category_id': 10,
      'name': 'Special Dish',
      'price': 45.0,
      'availability': 'available',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    SessionManager().clearSession();
    await db.close();
  });

  test('Food items category_id is preserved when categories are updated in-place (non-destructive)', () async {
    // Verify initial state
    final initial = await db.query('food_items', where: 'id = ?', whereArgs: [77]);
    expect(initial.first['category_id'], equals(10));

    // Simulate in-place update as performed by fixed _syncFromSupabase
    final existing = await db.query('food_categories', where: 'id = ?', whereArgs: [10]);
    expect(existing.isNotEmpty, isTrue);

    await db.update(
      'food_categories',
      {'name': 'Chicken Pastil Meals Updated', 'icon_url': 'drumstick'},
      where: 'id = ?',
      whereArgs: [10],
    );

    // Food item 77 must retain category_id = 10, NOT nullified by foreign key cascade
    final after = await db.query('food_items', where: 'id = ?', whereArgs: [77]);
    expect(after.first['category_id'], equals(10));
  });

  test('Admin changes food item category and Cashier sees the updated category', () async {
    // 1. Admin logs in
    SessionManager().setSession({
      'id': 1,
      'username': 'admin',
      'role': 'admin',
      'status': 'active',
    });

    // 2. Admin updates food item 77 category from 10 to 19 (Burgersteak)
    await foodRepo.updateFoodItem(77, {
      'name': 'Special Dish',
      'price': 45.0,
      'category_id': 19,
      'availability': 'available',
    });

    // 3. Admin logs out
    SessionManager().clearSession();

    // 4. Cashier logs in
    SessionManager().setSession({
      'id': 2,
      'username': 'cashier',
      'role': 'cashier',
      'status': 'active',
    });

    // 5. Cashier loads categories and food items
    final categories = await foodRepo.getCategories();
    final foods = await foodRepo.getAllFoodItems();

    expect(categories.any((c) => c['id'] == 19), isTrue);
    final cashierItem = foods.firstWhere((f) => f['id'] == 77);
    expect(cashierItem['category_id'], equals(19));
    expect(cashierItem['category_name'], equals('Burgersteak'));
  });

  test('repairOrphanFoodCategories preserves valid category assignments', () async {
    // Set item 77 to category 19
    await db.update('food_items', {'category_id': 19}, where: 'id = ?', whereArgs: [77]);

    // Run orphan repair
    await foodRepo.repairOrphanFoodCategories();

    // Category 19 is an active category; item 77 must NOT be forced back to 10
    final item = await db.query('food_items', where: 'id = ?', whereArgs: [77]);
    expect(item.first['category_id'], equals(19));
  });
}
