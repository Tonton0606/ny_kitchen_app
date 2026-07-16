import 'package:flutter/material.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class AdminNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: Theme.of(context).colorScheme.error, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Text('Confirm Logout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text('Are you sure you want to log out of your account?',
          style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      minWidth: 80,
      backgroundColor: cs.surface,
      indicatorColor: cs.primaryContainer,
      selectedIconTheme: IconThemeData(color: cs.primary),
      selectedLabelTextStyle: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold, fontSize: 13),
      unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      unselectedLabelTextStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
        child: CircleAvatar(
          backgroundColor: cs.primary.withValues(alpha: 0.2),
          child: Text('NY',
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: IconButton(
              icon: Icon(Icons.logout, color: cs.error),
              tooltip: 'Logout',
              onPressed: () => _showLogoutDialog(context),
            ),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
        NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Sales')),
        NavigationRailDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: Text('Food')),
        NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Accounts')),
        NavigationRailDestination(icon: Icon(Icons.security_outlined), selectedIcon: Icon(Icons.security), label: Text('Logs')),
        NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
      ],
    );
  }
}
