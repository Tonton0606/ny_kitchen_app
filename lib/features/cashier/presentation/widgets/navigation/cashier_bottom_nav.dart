import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
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
      selectedIconTheme: const IconThemeData(size: 26),
      unselectedIconTheme: const IconThemeData(size: 26),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Symbols.table_restaurant_rounded, weight: 500),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.receipt_long_rounded, weight: 500),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Symbols.history_rounded, weight: 500),
          label: 'History',
        ),
      ],
    );
  }
}
