import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/session/session_manager.dart';

void main() {
  group('SessionManager', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
      sessionManager.clearSession();
      sessionManager.lastActive = null;
    });

    test('setSession stores user data correctly', () {
      final user = {
        'id': 1,
        'role': 'admin',
        'full_name': 'Admin User'
      };
      
      sessionManager.setSession(user);
      
      expect(sessionManager.userId, equals(1));
      expect(sessionManager.role, equals('admin'));
      expect(sessionManager.fullName, equals('Admin User'));
      expect(sessionManager.currentUser, equals(user));
    });

    test('isLoggedIn returns true after setSession, false after clearSession', () {
      final user = {'id': 2, 'role': 'cashier'};
      
      expect(sessionManager.isLoggedIn, isFalse);
      
      sessionManager.setSession(user);
      expect(sessionManager.isLoggedIn, isTrue);
      
      sessionManager.clearSession();
      expect(sessionManager.isLoggedIn, isFalse);
    });

    test('isSessionExpired is false initially, true after 31+ min', () {
      final user = {'id': 3, 'role': 'cashier'};
      sessionManager.setSession(user);
      
      expect(sessionManager.isSessionExpired(), isFalse);
      
      // Simulate time passing 31 minutes
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 31));
      expect(sessionManager.isSessionExpired(), isTrue);
      expect(sessionManager.isLoggedIn, isFalse);
    });

    test('updateActivity resets expiry clock', () {
      final user = {'id': 4, 'role': 'admin'};
      sessionManager.setSession(user);
      
      // Simulate 29 minutes passed
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 29));
      expect(sessionManager.isSessionExpired(), isFalse);
      
      // User acts, clock resets
      sessionManager.updateActivity();
      expect(sessionManager.isSessionExpired(), isFalse);
      
      // 2 more minutes pass (total 31 since start, but 2 since last active)
      sessionManager.lastActive = DateTime.now().subtract(const Duration(minutes: 2));
      expect(sessionManager.isSessionExpired(), isFalse);
    });
    
    test('getCurrentUser (via property) returns correct user', () {
      final user = {'id': 5, 'username': 'testuser'};
      sessionManager.setSession(user);
      expect(sessionManager.currentUser, equals(user));
    });
  });
}
