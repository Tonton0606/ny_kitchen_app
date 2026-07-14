import 'package:flutter/material.dart';
import '../../../../../core/utils/responsive.dart';
import '../widgets/navigation/admin_nav_rail.dart';
import '../widgets/navigation/admin_drawer.dart';
import 'admin_dashboard_page.dart';
import 'sales_reports_page.dart';
import 'food_management_page.dart';
import 'account_management_page.dart';
import 'activity_logs_page.dart';
import 'admin_account_settings_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardPage(),
    const SalesReportsPage(),
    const FoodManagementPage(),
    const AccountManagementPage(),
    const ActivityLogsPage(),
    const AdminAccountSettingsPage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Sales Reports',
    'Food Management',
    'Account Management',
    'Activity Logs',
    'Account Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: isMobile ? AppBar(title: Text(_titles[_selectedIndex])) : null,
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            AdminNavRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
            ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
