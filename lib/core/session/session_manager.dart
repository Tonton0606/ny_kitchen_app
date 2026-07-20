import '../services/sync_service.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Map<String, dynamic>? currentUser;
  final SyncService _syncService = SyncService();

  void setSession(Map<String, dynamic> user) {
    currentUser = user;
    updateActivity();
    // Trigger backup when session starts
    _syncService.syncToCloud();
  }

  void clearSession() {
    currentUser = null;
    // Trigger backup when session ends
    _syncService.syncToCloud();
  }

  bool get isLoggedIn => currentUser != null && !isSessionExpired();
  int? get userId => currentUser?['id'] as int?;
  String? get role => currentUser?['role'] as String?;
  String? get fullName => currentUser?['full_name'] as String?;

  // --- Session Expiration Logic ---
  DateTime? _lastActive;
  static const Duration sessionTimeout = Duration(minutes: 30);

  void updateActivity() {
    _lastActive = DateTime.now();
  }

  bool isSessionExpired() {
    if (_lastActive == null) return false;
    final now = DateTime.now();
    return now.difference(_lastActive!) > sessionTimeout;
  }
}
