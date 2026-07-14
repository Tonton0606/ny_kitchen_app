import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import 'home_page.dart';
import 'transaction_history_page.dart';
import 'account_settings_page.dart';
import '../widgets/navigation/cashier_nav_rail.dart';
import '../widgets/navigation/cashier_bottom_nav.dart';

class CashierShell extends StatefulWidget {
  const CashierShell({super.key});

  @override
  State<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends State<CashierShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const CashierHomePage(),
    const TransactionHistoryPage(),
    const AccountSettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive(
        mobile: Column(children: [Expanded(child: _pages[_selectedIndex])]),
        tablet: Row(
          children: [
            CashierNavRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
        desktop: Row(
          children: [
            CashierNavRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
            ),
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Responsive.isMobile(context)
          ? CashierBottomNav(
              selectedIndex: _selectedIndex,
              onItemSelected: _onItemTapped,
            )
          : null,
    );
  }
}
