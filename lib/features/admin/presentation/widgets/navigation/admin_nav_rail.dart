import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class AdminNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onSettingsTap;

  const AdminNavRail({
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
              child: const Icon(
                Symbols.logout_rounded,
                color: AppColors.brandRed,
                size: 28,
                weight: 500,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Confirm Logout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: const TextStyle(fontSize: 15, color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
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
            child: const Text(
              'Logout',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: NavigationRailLabelType.none,
        backgroundColor: AppColors.darkCharcoal,
        selectedIconTheme: const IconThemeData(
          color: AppColors.goldenYellow,
          size: 27,
        ),
        unselectedIconTheme: const IconThemeData(
          color: Colors.white54,
          size: 27,
        ),
        indicatorColor: AppColors.goldenYellow.withValues(alpha: 0.25),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        groupAlignment: -0.25,
        leading: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, top: 12.0),
          child: GestureDetector(
            onTap: onSettingsTap,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.goldenYellow,
                child: Text(
                  'NY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(
                  height: 1,
                  color: Colors.white12,
                  indent: 16,
                  endIndent: 16,
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: IconButton(
                    icon: const Icon(
                      Symbols.logout_rounded,
                      color: Colors.white54,
                      weight: 500,
                    ),
                    tooltip: 'Logout',
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Symbols.dashboard_rounded, weight: 500),
            label: Text('Dashboard'),
          ),
          NavigationRailDestination(
            icon: Icon(Symbols.trending_up_rounded, weight: 500),
            label: Text('Sales'),
          ),
          NavigationRailDestination(
            icon: Icon(Symbols.menu_book_rounded, weight: 500),
            label: Text('Food'),
          ),
          NavigationRailDestination(
            icon: Icon(Symbols.badge_rounded, weight: 500),
            label: Text('Accounts'),
          ),
          NavigationRailDestination(
            icon: Icon(Symbols.assignment_rounded, weight: 500),
            label: Text('Logs'),
          ),
        ],
      ),
    );
  }
}
