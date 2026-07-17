import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onSettingsTap;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onSettingsTap,
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
                color: AppColors.brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: AppColors.brandRed, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(child: Text('Confirm Logout', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text('Are you sure you want to log out of your account?',
          style: const TextStyle(fontSize: 15, color: AppColors.mutedText),
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
              backgroundColor: AppColors.brandRed,
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
    return Drawer(
      backgroundColor: AppColors.darkCharcoal,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.darkCharcoal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onSettingsTap?.call();
                  },
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.goldenYellow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('NY',
                        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('N.Y Kitchen POS', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildItem(Icons.space_dashboard_outlined, Icons.space_dashboard, 'Dashboard', 0, context),
                _buildItem(Icons.trending_up_outlined, Icons.trending_up, 'Sales Reports', 1, context),
                _buildItem(Icons.menu_book_outlined, Icons.menu_book, 'Food Management', 2, context),
                _buildItem(Icons.badge_outlined, Icons.badge, 'Account Management', 3, context),
                _buildItem(Icons.assignment_outlined, Icons.assignment, 'Activity Logs', 4, context),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.brandRed),
            title: const Text('Logout', style: TextStyle(color: AppColors.brandRed, fontWeight: FontWeight.w600)),
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

  Widget _buildItem(IconData icon, IconData selectedIcon, String title, int index, BuildContext context) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(isSelected ? selectedIcon : icon,
        color: isSelected ? AppColors.goldenYellow : Colors.white70,
      ),
      title: Text(title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.goldenYellow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        onDestinationSelected(index);
        Navigator.pop(context);
      },
    );
  }
}
