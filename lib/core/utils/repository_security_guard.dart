import '../session/session_manager.dart';
import '../database/repositories/audit_repository.dart';
import 'security_exception.dart';

/// Centralized security guard for database repositories and data layers.
/// Enforces acting-session identity, role checks, and own-record restrictions (SEC-01 / AT02).
class RepositorySecurityGuard {
  static final AuditRepository _auditRepo = AuditRepository();

  /// Verifies that there is an active, unexpired session for an active account.
  /// Throws [SecurityException] and logs an audit failure on denial.
  static Future<Map<String, dynamic>> requireAuthenticated({
    required String module,
    required String action,
  }) async {
    final session = SessionManager();
    final user = session.currentUser;

    if (user == null) {
      await _auditRepo.logAction(
        module: module,
        action: action,
        status: 'Blocked',
        description: 'Unauthorized access attempt: No active authenticated session.',
      );
      throw const SecurityException(
        'Authentication required: No active session found.',
        code: 'UNAUTHENTICATED',
      );
    }

    if (session.isSessionExpired()) {
      await _auditRepo.logAction(
        userId: user['id'] as int?,
        username: user['username'] as String?,
        role: user['role'] as String?,
        module: module,
        action: action,
        status: 'Blocked',
        description: 'Unauthorized access attempt: Session expired.',
      );
      throw const SecurityException(
        'Session expired: Please log in again.',
        code: 'SESSION_EXPIRED',
      );
    }

    final status = (user['status'] as String?)?.toLowerCase();
    if (status == 'disabled' || status == 'inactive' || status == 'locked') {
      await _auditRepo.logAction(
        userId: user['id'] as int?,
        username: user['username'] as String?,
        role: user['role'] as String?,
        module: module,
        action: action,
        status: 'Blocked',
        description: 'Unauthorized access attempt: Account is $status.',
      );
      throw SecurityException(
        'Account is $status. Access denied.',
        code: 'ACCOUNT_INACTIVE',
      );
    }

    return user;
  }

  /// Verifies that the active session has administrator privileges.
  /// Throws [SecurityException] and logs an audit failure if the user is not an administrator.
  static Future<Map<String, dynamic>> requireAdmin({
    required String module,
    required String action,
  }) async {
    final user = await requireAuthenticated(module: module, action: action);
    final role = (user['role'] as String?)?.toLowerCase();

    if (role != 'admin') {
      await _auditRepo.logAction(
        userId: user['id'] as int?,
        username: user['username'] as String?,
        role: user['role'] as String?,
        module: module,
        action: action,
        status: 'Blocked',
        description: 'Permission denied: Administrator privileges required (Current role: $role).',
      );
      throw const SecurityException(
        'Access denied: Administrator privileges required.',
        code: 'FORBIDDEN_ROLE',
      );
    }

    return user;
  }

  /// Verifies that the active session is either an Administrator or the specific target user.
  /// Used for personal profile, settings, and password updates (own-record restrictions).
  static Future<Map<String, dynamic>> requireSelfOrAdmin(
    int targetUserId, {
    required String module,
    required String action,
  }) async {
    final user = await requireAuthenticated(module: module, action: action);
    final role = (user['role'] as String?)?.toLowerCase();
    final currentUserId = user['id'] as int?;

    if (role == 'admin' || currentUserId == targetUserId) {
      return user;
    }

    await _auditRepo.logAction(
      userId: currentUserId,
      username: user['username'] as String?,
      role: user['role'] as String?,
      module: module,
      action: action,
      status: 'Blocked',
      description: 'Access denied: Users may only access their own records (Attempted target user ID: $targetUserId).',
    );
    throw const SecurityException(
      'Access denied: You may only access your own records.',
      code: 'FORBIDDEN_OWN_RECORD',
    );
  }
}
