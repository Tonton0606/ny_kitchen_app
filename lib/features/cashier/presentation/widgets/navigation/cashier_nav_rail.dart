import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class CashierNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onSettingsTap;

  const CashierNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onSettingsTap,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
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
            icon: Icon(Symbols.table_restaurant_rounded, weight: 500),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Icon(Symbols.receipt_long_rounded, weight: 500),
            label: Text('Orders'),
          ),
          NavigationRailDestination(
            icon: Icon(Symbols.history_rounded, weight: 500),
            label: Text('History'),
          ),
        ],
      ),
    );
  }
}
