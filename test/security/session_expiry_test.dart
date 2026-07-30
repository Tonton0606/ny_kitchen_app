import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';

void main() {
  group('Session Expiry Tests', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      sessionManager.clearSession();
    });

    test('Fresh session is NOT expired', () {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'full_name': 'Test'});
      
      expect(sessionManager.isLoggedIn, isTrue);
      expect(sessionManager.isSessionExpired(), isFalse);
    });

    test('After 31 minutes of inactivity → expired', () {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'full_name': 'Test'});
      
      // Simulate 31 minutes passing
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 31));
      
      expect(sessionManager.isSessionExpired(), isTrue);
      expect(sessionManager.isLoggedIn, isFalse);
    });

    test('updateActivity() resets the timer', () {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'full_name': 'Test'});
      
      // Simulate 29 minutes passing
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 29));
      expect(sessionManager.isSessionExpired(), isFalse);
      
      // Update activity
      sessionManager.updateActivity();
      
      // Simulate another 29 minutes passing
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 29));
      expect(sessionManager.isSessionExpired(), isFalse);
    });

    test('clearSession() nullifies user data', () {
      sessionManager.setSession({'id': 1, 'role': 'admin', 'full_name': 'Test'});
      expect(sessionManager.currentUser, isNotNull);
      
      sessionManager.clearSession();
      expect(sessionManager.currentUser, isNull);
      expect(sessionManager.isLoggedIn, isFalse);
    });
  });
}
