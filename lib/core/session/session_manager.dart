import '../services/sync_service.dart';
import '../database/repositories/audit_repository.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Map<String, dynamic>? currentUser;
  final SyncService _syncService = SyncService();
  final AuditRepository _auditRepo = AuditRepository();

  void setSession(Map<String, dynamic> user) {
    currentUser = user;
    updateActivity();
    // Trigger backup when session starts
    _syncService.syncToCloud();
  }

  void clearSession({String reason = 'User logged out'}) {
    final user = currentUser;
    if (user != null) {
      // Audit logout / session termination (Gap 8)
      _auditRepo.logAction(
        userId: user['id'] as int?,
        username: user['username'] as String?,
        role: user['role'] as String?,
        module: 'Auth',
        action: reason.contains('expired') ? 'Session Expired' : 'User Logout',
        status: 'Success',
        description: reason,
      );
    }

    currentUser = null;
    // Trigger backup when session ends
    _syncService.syncToCloud();
  }


  bool get isLoggedIn => currentUser != null && !isSessionExpired();
  int? get userId => currentUser?['id'] as int?;
  String? get role => currentUser?['role'] as String?;
  String? get fullName => currentUser?['full_name'] as String?;
  bool get mustChangePassword => (currentUser?['must_change_password'] as int?) == 1;

  // --- Session Expiration Logic ---
  DateTime? _lastActive;
  static const Duration sessionTimeout = Duration(minutes: 30);
  
  // For testing purposes
  set lastActive(DateTime? time) => _lastActive = time;

  void updateActivity() {
    _lastActive = DateTime.now();
  }

  bool isSessionExpired() {
    if (_lastActive == null) return false;
    final now = DateTime.now();
    return now.difference(_lastActive!) > sessionTimeout;
  }
}
