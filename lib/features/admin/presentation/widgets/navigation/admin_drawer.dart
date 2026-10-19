import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/session/session_manager.dart';
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
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: const BorderSide(color: AppColors.softBorder, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              ),
              child: const Icon(
                LucideIcons.log_out,
                color: AppColors.brandRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your administrative session and log out?',
          style: TextStyle(fontSize: 14, color: AppColors.mutedBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            autofocus: true,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.darkCharcoal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              SessionManager().clearSession();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.goldenYellow,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    ),
                    child: const Center(
                      child: Text(
                        'NY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'N.Y Kitchen POS',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildItem(LucideIcons.layout_dashboard, 'Dashboard', 0, context),
                _buildItem(
                  LucideIcons.trending_up,
                  'Sales Reports',
                  1,
                  context,
                ),
                _buildItem(
                  LucideIcons.utensils,
                  'Food Management',
                  2,
                  context,
                ),
                _buildItem(
                  LucideIcons.users,
                  'Account Management',
                  3,
                  context,
                ),
                _buildItem(
                  LucideIcons.clipboard_list,
                  'Activity Logs',
                  4,
                  context,
                ),
                _buildItem(
                  LucideIcons.database_backup,
                  'Backup & Restore',
                  5,
                  context,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white12),
          ListTile(
            leading: const Icon(
              LucideIcons.log_out,
              color: AppColors.brandRed,
              size: 22,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: AppColors.brandRed,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  Widget _buildItem(
    IconData icon,
    String title,
    int index,
    BuildContext context,
  ) {
    final isSelected = selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.goldenYellow : Colors.white70,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.goldenYellow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesignTokens.radius8)),
      onTap: () {
        onDestinationSelected(index);
        Navigator.pop(context);
      },
    );
  }
}
