import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../utils/security_utils.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Retrieve a user by username and password, handling lockouts
  Future<Map<String, dynamic>?> login(String username, String password) async {
    final db = await _dbHelper.database;
    // Hashes are now stored with their salts in the DB, so we verify against the DB record later.

    // First check if the user exists and their status
    final userCheck = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (userCheck.isEmpty) {
      return null; // User does not exist
    }

    final userRow = userCheck.first;
    final int userId = userRow['id'] as int;
    final String status = userRow['status'] as String;
    final int failedAttempts = (userRow['failed_login_count'] as int?) ?? 0;

    if (status != 'active') {
      return null; // Account is locked or inactive
    }

    if (SecurityUtils.verifyPassword(password, userRow['password_hash'] as String)) {
      // Success! Reset failed login count and update last_login
      await db.update(
        'users',
        {
          'last_login': DateTime.now().toIso8601String(),
          'failed_login_count': 0,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      // Re-fetch the updated user to return
      final updatedMaps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      return updatedMaps.first;
    } else {
      // Failed login attempt
      final newFailedCount = failedAttempts + 1;
      final updates = <String, dynamic>{
        'failed_login_count': newFailedCount,
      };

      if (newFailedCount >= 5) {
        updates['status'] = 'locked'; // Lock account after 5 failed attempts
      }

      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return null;
    }
  }

  // Change password
  Future<bool> changePassword(int userId, String newPassword) async {
    final db = await _dbHelper.database;
    final hashedPassword = SecurityUtils.hashPassword(newPassword);
    
    final changes = await db.update(
      'users',
      {'password_hash': hashedPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return changes > 0;
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await _dbHelper.database;
    return await db.query('users', orderBy: 'full_name ASC');
  }

  // Create a new user
  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await _dbHelper.database;
    user['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  // Update a user
  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete/Disable a user (We prefer changing status to 'inactive' over hard delete)
  Future<int> disableUser(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      'users',
      {'status': 'inactive'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
