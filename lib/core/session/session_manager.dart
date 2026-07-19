class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  Map<String, dynamic>? currentUser;

  void setSession(Map<String, dynamic> user) {
    currentUser = user;
  }

  void clearSession() {
    currentUser = null;
  }

  bool get isLoggedIn => currentUser != null;
  int? get userId => currentUser?['id'] as int?;
  String? get role => currentUser?['role'] as String?;
  String? get fullName => currentUser?['full_name'] as String?;
}
