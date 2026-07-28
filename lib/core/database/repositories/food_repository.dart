import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../services/sync_service.dart';

class FoodRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();

  // Retrieve all active and available food items
  Future<List<Map<String, dynamic>>> getAvailableFoodItems() async {
    final db = await _dbHelper.database;
    return await db.query(
      'food_items',
      where: 'status = ? AND availability = ?',
      whereArgs: ['active', 'available'],
      orderBy: 'name ASC',
    );
  }

  // Retrieve ALL food items (used for Admin food management table)
  Future<List<Map<String, dynamic>>> getAllFoodItems() async {
    final db = await _dbHelper.database;
    // Left join with categories to get the category name if we want to display it
    final sql = '''
      SELECT f.*, c.name as category_name 
      FROM food_items f
      LEFT JOIN food_categories c ON f.category_id = c.id
      WHERE f.status != 'archived'
      ORDER BY f.name ASC
    ''';
    return await db.rawQuery(sql);
  }

  // Create a new food item
  Future<int> insertFoodItem(Map<String, dynamic> foodItem) async {
    final db = await _dbHelper.database;
    foodItem['created_at'] = DateTime.now().toIso8601String();
    if (foodItem['image_path'] != null) {
      foodItem['image_path'] = await _syncService.uploadImage(
        foodItem['image_path'],
      );
    }
    int id = await db.insert(
      'food_items',
      foodItem,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _syncService.syncToCloud();
    return id;
  }

  // Update an existing food item
  Future<int> updateFoodItem(int id, Map<String, dynamic> foodItem) async {
    final db = await _dbHelper.database;
    foodItem['updated_at'] = DateTime.now().toIso8601String();
    if (foodItem['image_path'] != null) {
      foodItem['image_path'] = await _syncService.uploadImage(
        foodItem['image_path'],
      );
    }
    int count = await db.update(
      'food_items',
      foodItem,
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.syncToCloud();
    return count;
  }

  // Delete/Archive a food item (We prefer archiving to maintain receipt history integrity)
  Future<int> archiveFoodItem(int id) async {
    final db = await _dbHelper.database;
    int count = await db.update(
      'food_items',
      {'status': 'archived', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.syncToCloud();
    return count;
  }

  // --- Category Management --- //

  Future<List<Map<String, dynamic>>> getCategories() async {
    await repairOrphanFoodCategories();
    final db = await _dbHelper.database;
    return await db.query(
      'food_categories',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'id ASC',
    );
  }

  Future<void> repairOrphanFoodCategories() async {
    final db = await _dbHelper.database;
    // Check if there's any active category
    final cats = await db.query(
      'food_categories',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'id ASC',
    );
    if (cats.isEmpty) {
      // If no active categories, do not auto-create one. Just skip orphan repair.
      return;
    }
    
    int defaultCatId = cats.first['id'] as int;

    // Reassign food items with NULL category_id or invalid category_id
    final validIds = cats.map((c) => c['id'] as int).toList();
    final sql =
        "SELECT id, category_id FROM food_items WHERE status != 'archived'";
    final foods = await db.rawQuery(sql);

    for (var f in foods) {
      final catId = f['category_id'] as int?;
      if (catId == null || !validIds.contains(catId)) {
        await db.update(
          'food_items',
          {
            'category_id': defaultCatId,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [f['id']],
        );
      }
    }
  }

  Future<int> insertCategory(String name, {String? iconUrl}) async {
    final db = await _dbHelper.database;

    String finalIcon = iconUrl ?? '🍽️';
    if (finalIcon.startsWith('http') ||
        finalIcon.startsWith('/') ||
        finalIcon.startsWith('C:')) {
      try {
        final uploaded = await _syncService.uploadImage(finalIcon);
        if (uploaded != null) finalIcon = uploaded;
      } catch (_) {}
    }

    int id = await db.insert('food_categories', {
      'name': name,
      'icon_url': finalIcon,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    });
    try {
      await _syncService.syncToCloud();
    } catch (e) {
      print('Cloud sync deferred: $e');
    }
    return id;
  }

  Future<int> updateCategory(int id, String name, {String? iconUrl}) async {
    final db = await _dbHelper.database;
    final data = <String, dynamic>{'name': name};
    if (iconUrl != null) {
      String finalIcon = iconUrl;
      if (finalIcon.startsWith('http') ||
          finalIcon.startsWith('/') ||
          finalIcon.startsWith('C:')) {
        try {
          final uploaded = await _syncService.uploadImage(finalIcon);
          if (uploaded != null) finalIcon = uploaded;
        } catch (_) {}
      }
      data['icon_url'] = finalIcon;
    }
    int count = await db.update(
      'food_categories',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
    try {
      await _syncService.syncToCloud();
    } catch (e) {
      print('Cloud sync deferred: $e');
    }
    return count;
  }

  Future<int> archiveCategory(int id) async {
    final db = await _dbHelper.database;
    // Before archiving category, reassign items to another category
    final activeCats = await db.query(
      'food_categories',
      where: 'status = ? AND id != ?',
      whereArgs: ['active', id],
      orderBy: 'id ASC',
    );
    if (activeCats.isNotEmpty) {
      final fallbackId = activeCats.first['id'] as int;
      await db.update(
        'food_items',
        {'category_id': fallbackId},
        where: 'category_id = ?',
        whereArgs: [id],
      );
    }

    int count = await db.update(
      'food_categories',
      {'status': 'archived'},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.syncToCloud();
    return count;
  }
}
