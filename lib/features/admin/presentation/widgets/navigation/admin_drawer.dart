import 'package:flutter/material.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AdminDrawer({
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
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: cs.primary),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('NY',
                      style: TextStyle(color: cs.primary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Admin Portal', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('N.Y Kitchen POS', style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0, cs, context),
                _buildItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Sales Reports', 1, cs, context),
                _buildItem(Icons.restaurant_menu_outlined, Icons.restaurant_menu, 'Food Management', 2, cs, context),
                _buildItem(Icons.people_outline, Icons.people, 'Account Management', 3, cs, context),
                _buildItem(Icons.security_outlined, Icons.security, 'Activity Logs', 4, cs, context),
                _buildItem(Icons.settings_outlined, Icons.settings, 'Account Settings', 5, cs, context),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant),
          ListTile(
            leading: Icon(Icons.logout, color: cs.error),
            title: Text('Logout', style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, IconData selectedIcon, String title, int index, ColorScheme cs, BuildContext context) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(isSelected ? selectedIcon : icon,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(title,
        style: TextStyle(
          color: isSelected ? cs.onSurface : cs.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        onDestinationSelected(index);
        Navigator.pop(context);
      },
    );
  }
}
