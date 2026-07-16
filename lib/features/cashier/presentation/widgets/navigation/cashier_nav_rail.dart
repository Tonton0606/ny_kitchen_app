import 'package:flutter/material.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class CashierNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const CashierNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  void _showLogoutDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            child: const Text('Logout'),
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
      backgroundColor: cs.surface,
      selectedIconTheme: IconThemeData(color: cs.primary),
      selectedLabelTextStyle: TextStyle(
        color: cs.onSurface,
        fontWeight: FontWeight.bold,
      ),
      unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      unselectedLabelTextStyle: TextStyle(color: cs.onSurfaceVariant),
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
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('History'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Account'),
        ),
      ],
    );
  }
}
