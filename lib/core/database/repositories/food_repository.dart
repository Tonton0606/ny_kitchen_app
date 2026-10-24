import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../services/sync_service.dart';
import '../../utils/repository_security_guard.dart';
import '../../utils/security_exception.dart';
import 'audit_repository.dart';

class FoodRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();
  final AuditRepository _auditRepo = AuditRepository();

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

  // Retrieve ALL food items (used for Admin food management table and Cashier menu catalog)
  Future<List<Map<String, dynamic>>> getAllFoodItems({bool includeArchived = false}) async {
    await RepositorySecurityGuard.requireAuthenticated(
      module: 'Food Management',
      action: 'View All Food Items',
    );
    final db = await _dbHelper.database;
    final whereClause = includeArchived ? '' : "WHERE f.status != 'archived'";
    final sql = '''
      SELECT f.*, c.name as category_name 
      FROM food_items f
      LEFT JOIN food_categories c ON f.category_id = c.id
      $whereClause
      ORDER BY f.name ASC
    ''';
    final results = await db.rawQuery(sql);
    return results.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  // Create a new food item
  Future<int> insertFoodItem(Map<String, dynamic> foodItem, {int? adminId, String? adminUsername}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Create Food Item',
    );
    final db = await _dbHelper.database;

    final name = (foodItem['name'] as String?)?.trim() ?? '';
    if (name.isNotEmpty) {
      final existing = await db.rawQuery(
        'SELECT id, name, status FROM food_items WHERE LOWER(name) = LOWER(?)',
        [name],
      );
      if (existing.isNotEmpty) {
        final existingItem = existing.first;
        if (existingItem['status'] == 'archived') {
          throw const SecurityException(
            'A dish with this name is currently archived. Please restore it from the Archived filter instead of creating a duplicate.',
            code: 'DUPLICATE_ARCHIVED_FOOD',
          );
        } else {
          throw const SecurityException(
            'An active food item with this name already exists.',
            code: 'DUPLICATE_ACTIVE_FOOD',
          );
        }
      }
    }

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

    // Audit food creation (Gap 9 / SEC-01) - use authoritative admin session identity
    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Created',
      status: 'Success',
      description: 'Created food item "${foodItem['name']}" (Price: ${foodItem['price']})',
    );

    return id;
  }

  // Update an existing food item
  Future<int> updateFoodItem(int id, Map<String, dynamic> foodItem, {int? adminId, String? adminUsername}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Update Food Item',
    );
    final db = await _dbHelper.database;

    if (foodItem.containsKey('name')) {
      final name = (foodItem['name'] as String?)?.trim() ?? '';
      if (name.isNotEmpty) {
        final existing = await db.rawQuery(
          'SELECT id, name, status FROM food_items WHERE LOWER(name) = LOWER(?) AND id != ?',
          [name, id],
        );
        if (existing.isNotEmpty) {
          final existingItem = existing.first;
          if (existingItem['status'] == 'archived') {
            throw const SecurityException(
              'A dish with this name is currently archived. Please choose a different name or restore the archived dish.',
              code: 'DUPLICATE_ARCHIVED_FOOD',
            );
          } else {
            throw const SecurityException(
              'Another active food item with this name already exists.',
              code: 'DUPLICATE_ACTIVE_FOOD',
            );
          }
        }
      }
    }

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

    // Audit food update (Gap 9 / SEC-01) - use authoritative admin session identity
    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Updated',
      status: 'Success',
      description: 'Updated food item ID $id (${foodItem['name'] ?? 'Fields: ${foodItem.keys.join(', ')}'})',
    );

    return count;
  }

  // Delete/Archive a food item (We prefer archiving to maintain receipt history integrity)
  Future<int> archiveFoodItem(int id, {int? adminId, String? adminUsername}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Archive Food Item',
    );
    final db = await _dbHelper.database;
    int count = await db.update(
      'food_items',
      {'status': 'archived', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.syncToCloud();

    // Audit food archive (Gap 9 / SEC-01) - use authoritative admin session identity
    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Archived',
      status: 'Success',
      description: 'Archived food item ID $id',
    );

    return count;
  }

  // Unarchive/Restore a food item to active status
  Future<int> unarchiveFoodItem(int id, {int? adminId, String? adminUsername}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Unarchive Food Item',
    );
    final db = await _dbHelper.database;
    int count = await db.update(
      'food_items',
      {'status': 'active', 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.syncToCloud();

    // Audit food unarchive (Gap 9 / SEC-01) - use authoritative admin session identity
    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Restored',
      status: 'Success',
      description: 'Restored archived food item ID $id to active menu',
    );

    return count;
  }


  // --- Category Management --- //

  Future<List<Map<String, dynamic>>> getCategories() async {
    await repairOrphanFoodCategories();
    final db = await _dbHelper.database;
    final results = await db.query(
      'food_categories',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'id ASC',
    );
    return results.map((r) => Map<String, dynamic>.from(r)).toList();
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
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Create Food Category',
    );
    final db = await _dbHelper.database;

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Category name cannot be empty.');
    }
    if (trimmedName.length > 30) {
      throw Exception('Category name cannot exceed 30 characters.');
    }
    if (trimmedName.toLowerCase() == 'all') {
      throw Exception('Category name cannot be "All".');
    }

    String finalIcon = iconUrl ?? '🍽️';
    if (finalIcon.startsWith('http') ||
        finalIcon.startsWith('/') ||
        finalIcon.startsWith('C:')) {
      try {
        final uploaded = await _syncService.uploadImage(finalIcon);
        if (uploaded != null) finalIcon = uploaded;
      } catch (_) {}
    }

    final existing = await db.query(
      'food_categories',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmedName.toLowerCase()],
    );

    int id;
    if (existing.isNotEmpty) {
      final active = existing.where((c) => c['status'] == 'active');
      if (active.isNotEmpty) {
        throw Exception('Category "$trimmedName" already exists.');
      }
      final cat = existing.first;
      final updateData = <String, dynamic>{
        'name': trimmedName,
        'status': 'active',
        'icon_url': finalIcon,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await db.update(
        'food_categories',
        updateData,
        where: 'id = ?',
        whereArgs: [cat['id']],
      );
      id = cat['id'] as int;

      // Clean up any extra archived copies that share the same lowercased name
      await db.delete(
        'food_categories',
        where: 'LOWER(name) = ? AND id != ?',
        whereArgs: [trimmedName.toLowerCase(), id],
      );
    } else {
      id = await db.insert('food_categories', {
        'name': trimmedName,
        'icon_url': finalIcon,
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }

    try {
      await _syncService.syncToCloud();
    } catch (_) {}

    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Category Created',
      status: 'Success',
      description: 'Created/Reactivated food category "$trimmedName" (ID: $id)',
    );

    return id;
  }

  Future<int> updateCategory(int id, String name, {String? iconUrl}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Update Food Category',
    );
    final db = await _dbHelper.database;
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Category name cannot be empty.');
    }
    if (trimmedName.length > 30) {
      throw Exception('Category name cannot exceed 30 characters.');
    }
    if (trimmedName.toLowerCase() == 'all') {
      throw Exception('Category name cannot be "All".');
    }

    final duplicates = await db.query(
      'food_categories',
      where: 'LOWER(name) = ? AND id != ?',
      whereArgs: [trimmedName.toLowerCase(), id],
    );

    if (duplicates.isNotEmpty) {
      final active = duplicates.where((c) => c['status'] == 'active');
      if (active.isNotEmpty) {
        throw Exception('Category "$trimmedName" already exists.');
      }
      // If only archived duplicates exist, clean them up before renaming
      await db.delete(
        'food_categories',
        where: 'LOWER(name) = ? AND status = ? AND id != ?',
        whereArgs: [trimmedName.toLowerCase(), 'archived', id],
      );
    }

    final data = <String, dynamic>{
      'name': trimmedName,
      'updated_at': DateTime.now().toIso8601String(),
    };
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
    } catch (_) {}

    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Category Updated',
      status: 'Success',
      description: 'Updated food category ID $id to "$trimmedName"',
    );

    return count;
  }

  Future<int> archiveCategory(int id) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Archive Food Category',
    );
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    // Query category name for audit log before updating
    final targetCat = await db.query(
      'food_categories',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final catName = targetCat.isNotEmpty ? targetCat.first['name'] as String? : 'ID $id';

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
        {
          'category_id': fallbackId,
          'updated_at': now,
        },
        where: 'category_id = ?',
        whereArgs: [id],
      );
    }

    int count = await db.update(
      'food_categories',
      {
        'status': 'archived',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      await _syncService.syncToCloud();
    } catch (_) {}

    // Audit category archival
    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Category Archived',
      status: 'Success',
      description: 'Archived food category "$catName" (ID: $id)',
    );

    return count;
  }

  Future<List<Map<String, dynamic>>> getArchivedCategories() async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'food_categories',
      where: 'status = ?',
      whereArgs: ['archived'],
      orderBy: 'name ASC',
    );
    return results.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<int> unarchiveCategory(int id) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Food Management',
      action: 'Restore Food Category',
    );
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final target = await db.query(
      'food_categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (target.isEmpty) throw Exception('Category not found.');
    final catName = target.first['name'] as String;

    // Check if an active category with the same name already exists
    final activeExisting = await db.query(
      'food_categories',
      where: 'LOWER(name) = ? AND status = ? AND id != ?',
      whereArgs: [catName.toLowerCase(), 'active', id],
    );
    if (activeExisting.isNotEmpty) {
      throw Exception('An active category named "$catName" already exists.');
    }

    int count = await db.update(
      'food_categories',
      {
        'status': 'active',
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      await _syncService.syncToCloud();
    } catch (_) {}

    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? 'Admin',
      role: 'admin',
      module: 'Food Management',
      action: 'Food Category Restored',
      status: 'Success',
      description: 'Restored archived food category "$catName" (ID: $id)',
    );

    return count;
  }
}
