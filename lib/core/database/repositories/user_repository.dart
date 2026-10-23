import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../utils/security_utils.dart';
import '../../utils/security_exception.dart';
import '../../utils/repository_security_guard.dart';
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
      // Audit log failed login for non-existent username (never log password)
      await _auditRepo.logAction(
        username: username,
        module: 'Auth',
        action: 'Failed Login',
        status: 'Warning',
        description: 'Failed login attempt: username not found',
      );
      try {
        await db.insert('login_attempts', {
          'username': username,
          'status': 'failed_unknown_user',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      return null; // User does not exist
    }

    final userRow = userCheck.first;
    final int userId = userRow['id'] as int;
    final String status = userRow['status'] as String;
    final int failedAttempts = (userRow['failed_login_count'] as int?) ?? 0;

    if (status != 'active') {
      // Audit log failed login for inactive/locked account (never log password)
      await _auditRepo.logAction(
        userId: userId,
        username: username,
        role: userRow['role'] as String?,
        module: 'Auth',
        action: 'Failed Login',
        status: 'Warning',
        description: 'Failed login attempt on $status account',
      );
      try {
        await db.insert('login_attempts', {
          'username': username,
          'status': 'failed_account_$status',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
      return null; // Account is locked or inactive
    }

    if (SecurityUtils.verifyPassword(password, userRow['password_hash'] as String)) {
      final currentHash = userRow['password_hash'] as String;
      final updates = <String, dynamic>{
        'last_login': DateTime.now().toIso8601String(),
        'failed_login_count': 0,
      };

      // Transparent re-hash on login with modern target iterations (Task B1)
      if (SecurityUtils.needsRehash(currentHash)) {
        final upgradedHash = SecurityUtils.hashPassword(password);
        updates['password_hash'] = upgradedHash;
      }

      // Success! Reset failed login count and update last_login (plus upgraded hash if needed)
      await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      // Audit successful login (Gap 7)
      await _auditRepo.logAction(
        userId: userId,
        username: username,
        role: userRow['role'] as String?,
        module: 'Auth',
        action: 'Login Successful',
        status: 'Success',
        description: 'User logged in successfully',
      );

      try {
        await db.insert('login_attempts', {
          'username': username,
          'status': 'success',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      // Re-fetch the updated user to return
      final updatedMaps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      return Map<String, dynamic>.from(updatedMaps.first);

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

      try {
        await db.insert('login_attempts', {
          'username': username,
          'status': newFailedCount >= 5 ? 'locked' : 'failed_password',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

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
    // SEC-01 & SEC-05: Enforce password policy at logic layer and verify authorization
    final policyError = SecurityUtils.validatePassword(newPassword);
    if (policyError != null) {
      await _auditRepo.logAction(
        userId: userId,
        module: 'Account',
        action: 'Change Password',
        status: 'Blocked',
        description: 'Password policy violation: $policyError',
      );
      throw SecurityException(policyError, code: 'WEAK_PASSWORD');
    }

    final actor = await RepositorySecurityGuard.requireSelfOrAdmin(
      userId,
      module: 'Account',
      action: 'Change Password',
    );

    final db = await _dbHelper.database;
    final hashedPassword = SecurityUtils.hashPassword(newPassword);
    
    final changes = await db.update(
      'users',
      {
        'password_hash': hashedPassword,
        'must_change_password': 0,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (changes > 0) {
      await _auditRepo.logAction(
        userId: userId,
        username: actor['username'] as String?,
        role: actor['role'] as String?,
        module: 'Account',
        action: 'Password Changed',
        status: 'Success',
      );
    }
    
    return changes > 0;
  }

  // Get user by ID (secured to self or admin)
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    await RepositorySecurityGuard.requireSelfOrAdmin(
      userId,
      module: 'User Management',
      action: 'Get User By ID',
    );
    final db = await _dbHelper.database;
    final res = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return res.isNotEmpty ? res.first : null;
  }

  // Change password with verification of current password
  Future<bool> changePasswordWithVerification(int userId, String currentPassword, String newPassword) async {
    final user = await getUserById(userId);
    if (user == null) {
      throw const SecurityException('User not found', code: 'USER_NOT_FOUND');
    }
    final storedHash = user['password_hash'] as String? ?? '';
    if (!SecurityUtils.verifyPassword(currentPassword, storedHash)) {
      await _auditRepo.logAction(
        userId: userId,
        username: user['username'] as String?,
        role: user['role'] as String?,
        module: 'Account',
        action: 'Change Password',
        status: 'Blocked',
        description: 'Current password verification failed during self-service password update.',
      );
      throw const SecurityException('Current password verification failed', code: 'INVALID_CURRENT_PASSWORD');
    }
    return await changePassword(userId, newPassword);
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    await RepositorySecurityGuard.requireAdmin(
      module: 'User Management',
      action: 'View All Users',
    );
    final db = await _dbHelper.database;
    return await db.query('users', orderBy: 'full_name ASC');
  }

  // Create a new user
  Future<int> createUser(Map<String, dynamic> user, {int? adminId, String? adminUsername}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'User Management',
      action: 'Create User',
    );
    final db = await _dbHelper.database;
    user['created_at'] = DateTime.now().toIso8601String();
    if (!user.containsKey('must_change_password')) {
      user['must_change_password'] = 1;
    }
    final newId = await db.insert('users', user, conflictAlgorithm: ConflictAlgorithm.abort);
    
    // Audit user creation (Gap 9 / SEC-01) - use authoritative acting session identity
    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'User Management',
      action: 'User Created',
      status: 'Success',
      description: 'Created user "${user['username']}" with role "${user['role']}"',
    );
    
    return newId;
  }

  // Update a user
  Future<int> updateUser(int id, Map<String, dynamic> user, {int? adminId, String? adminUsername}) async {
    // If updating privileged fields (role, status, lockout counter), strictly require Admin
    final Map<String, dynamic> actor;
    if (user.containsKey('role') || user.containsKey('status') || user.containsKey('failed_login_count')) {
      actor = await RepositorySecurityGuard.requireAdmin(
        module: 'User Management',
        action: 'Update User Role/Status',
      );
    } else {
      actor = await RepositorySecurityGuard.requireSelfOrAdmin(
        id,
        module: 'User Management',
        action: 'Update User Profile',
      );
    }

    final db = await _dbHelper.database;
    final count = await db.update(
      'users',
      user,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Audit user update (Gap 9 / SEC-01) - authoritative actor identity, never log password_hash
    final sanitizedKeys = user.keys.where((k) => k != 'password_hash').join(', ');
    await _auditRepo.logAction(
      userId: actor['id'] as int?,
      username: actor['username'] as String? ?? adminUsername ?? 'Admin',
      role: actor['role'] as String? ?? 'admin',
      module: 'User Management',
      action: 'User Updated',
      status: 'Success',
      description: 'Updated user ID $id (modified fields: $sanitizedKeys)',
    );

    return count;
  }

  // Delete/Disable a user (We prefer changing status to 'inactive' over hard delete)
  Future<int> disableUser(int id, {int? adminId, String? adminUsername}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'User Management',
      action: 'Disable User',
    );

    if (admin['id'] == id) {
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String?,
        role: admin['role'] as String?,
        module: 'User Management',
        action: 'Disable User',
        status: 'Blocked',
        description: 'Self-disable prohibited: Administrator attempted to disable own active account.',
      );
      throw const SecurityException(
        'Self-lockout prohibited: Administrators cannot disable their own active account.',
        code: 'SELF_DISABLE_PROHIBITED',
      );
    }

    final db = await _dbHelper.database;
    final count = await db.update(
      'users',
      {'status': 'inactive'},
      where: 'id = ?',
      whereArgs: [id],
    );

    // Audit user disable (Gap 9 / SEC-01)
    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'User Management',
      action: 'User Disabled',
      status: 'Success',
      description: 'Disabled user account ID $id',
    );

    return count;
  }

  // Unlock user
  Future<void> unlockUser(int id, [String? adminName]) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Security',
      action: 'Unlock User',
    );

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
        description: 'Account unlocked by ${admin['username'] ?? adminName ?? 'Admin'}',
      );
    }
  }

  // Enable a disabled user account with a mandatory temporary password and reset failed login counter
  Future<int> enableUserWithTemporaryPassword(
    int id,
    String temporaryPassword, {
    int? adminId,
    String? adminUsername,
  }) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'User Management',
      action: 'Enable User',
    );

    final policyError = SecurityUtils.validatePassword(temporaryPassword);
    if (policyError != null) {
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String? ?? adminUsername ?? 'Admin',
        role: 'admin',
        module: 'User Management',
        action: 'Enable User',
        status: 'Blocked',
        description: 'Password policy violation while enabling user ID $id: $policyError',
      );
      throw SecurityException(policyError, code: 'WEAK_PASSWORD');
    }

    final db = await _dbHelper.database;
    final hashedPassword = SecurityUtils.hashPassword(temporaryPassword);
    final count = await db.update(
      'users',
      {
        'status': 'active',
        'failed_login_count': 0,
        'must_change_password': 1,
        'password_hash': hashedPassword,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'User Management',
      action: 'User Enabled',
      status: 'Success',
      description: 'Enabled user account ID $id with mandatory temporary password reset',
    );

    return count;
  }

  // Enable a user account without resetting credentials
  Future<int> enableUser(int id, {int? adminId, String? adminUsername}) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'User Management',
      action: 'Enable User',
    );

    final db = await _dbHelper.database;
    final count = await db.update(
      'users',
      {
        'status': 'active',
        'failed_login_count': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    await _auditRepo.logAction(
      userId: admin['id'] as int?,
      username: admin['username'] as String? ?? adminUsername ?? 'Admin',
      role: 'admin',
      module: 'User Management',
      action: 'User Enabled',
      status: 'Success',
      description: 'Enabled user account ID $id and reset failed login attempts',
    );

    return count;
  }
}


