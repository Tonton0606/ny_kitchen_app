import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../utils/security_utils.dart';
import 'audit_repository.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AuditRepository _auditRepo = AuditRepository();

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
        await _auditRepo.logAction(
          userId: userId,
          username: username,
          role: userRow['role'] as String?,
          module: 'Auth',
          action: 'Account Locked',
          status: 'Critical',
          description: 'Account locked due to 5 consecutive failed logins',
        );
      } else {
        await _auditRepo.logAction(
          userId: userId,
          username: username,
          role: userRow['role'] as String?,
          module: 'Auth',
          action: 'Failed Login',
          status: 'Warning',
          description: 'Failed login attempt ($newFailedCount/5)',
        );
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
    
    if (changes > 0) {
      await _auditRepo.logAction(
        userId: userId,
        module: 'Account',
        action: 'Password Changed',
        status: 'Success',
      );
    }
    
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

  // Unlock user
  Future<void> unlockUser(int id, String adminName) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      {'status': 'active', 'failed_login_count': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    final userMaps = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (userMaps.isNotEmpty) {
      final user = userMaps.first;
      await _auditRepo.logAction(
        userId: id,
        username: user['username'] as String,
        role: user['role'] as String,
        module: 'Security',
        action: 'Account Unlocked',
        status: 'Success',
        description: 'Account unlocked by $adminName',
      );
    }
  }

  // Update face encoding
  Future<void> updateFaceEncoding(int userId, String encodingJson) async {
    final db = await _dbHelper.database;
    final encryptedEncoding = await SecurityUtils.encryptFaceEncoding(encodingJson);
    await db.update(
      'users',
      {'face_encoding': encryptedEncoding},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Get users with face encoding
  Future<List<Map<String, dynamic>>> getUsersWithFaceEncoding() async {
    final db = await _dbHelper.database;
    final users = await db.query(
      'users',
      where: 'status = ? AND face_encoding IS NOT NULL',
      whereArgs: ['active'],
    );
    
    // Decrypt the face encodings
    final decryptedUsers = await Future.wait(users.map((user) async {
      final mutableUser = Map<String, dynamic>.from(user);
      if (mutableUser['face_encoding'] != null) {
        mutableUser['face_encoding'] = await SecurityUtils.decryptFaceEncoding(mutableUser['face_encoding'] as String);
      }
      return mutableUser;
    }));
    return decryptedUsers;
  }
}
