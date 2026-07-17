import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class CashierBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback? onSettingsTap;

  const CashierBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: onItemSelected,
      backgroundColor: AppColors.darkCharcoal,
      selectedItemColor: AppColors.goldenYellow,
      unselectedItemColor: Colors.white54,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedIconTheme: const IconThemeData(size: 30),
      unselectedIconTheme: const IconThemeData(size: 24),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.table_restaurant_outlined),
          activeIcon: Icon(Icons.table_restaurant),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'History',
        ),
      ],
    );
  }
}
