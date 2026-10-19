import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';
import '../pages/login_page.dart';

/// A widget that acts as a "Route Guard".
/// It wraps around a screen and checks if the user is authorized.
/// If their session is expired or their role is wrong, it boots them to Login.
class GuardedRoute extends StatefulWidget {
  final Widget child;
  final List<String> allowedRoles;

  const GuardedRoute({
    super.key,
    required this.child,
    required this.allowedRoles,
  });

  @override
  State<GuardedRoute> createState() => _GuardedRouteState();
}

class _GuardedRouteState extends State<GuardedRoute> {
  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = SessionManager();
      
      // 1. Check if logged in and not expired
      if (!session.isLoggedIn) {
        session.clearSession();
        _redirectToLogin("Session expired. Please log in again.");
        return;
      }

      // 2. Check if password change is required (Gap 3)
      if (session.mustChangePassword) {
        _redirectToLogin("Password change required before accessing the system.");
        return;
      }

      // 3. Check if their role is allowed on this screen
      if (!widget.allowedRoles.contains(session.role)) {
        _redirectToLogin("Unauthorized access. Wrong role.");
        return;
      }
    });
  }

  void _redirectToLogin(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.brandRed),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we make it here, the frame renders while the check runs post-frame.
    // If unauthorized, they will be kicked out immediately.
    return widget.child;
  }
}
