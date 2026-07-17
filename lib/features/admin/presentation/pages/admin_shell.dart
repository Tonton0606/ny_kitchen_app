import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
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
  bool _showSettings = false;

  static const double _navRailWidth = 76.0;
  static const double _panelWidth = 500.0;

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    SalesReportsPage(),
    FoodManagementPage(),
    AccountManagementPage(),
    ActivityLogsPage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Sales Reports',
    'Food Management',
    'Account Management',
    'Activity Logs',
  ];

  void _onItemTapped(int index) {
    if (_showSettings) _closeSettings();
    setState(() => _selectedIndex = index);
  }

  void _openSettings() {
    if (Responsive.isMobile(context)) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          builder: (_, scrollController) => _SettingsShell(
            onClose: () => Navigator.pop(context),
            child: const AdminAccountSettingsPage(),
          ),
        ),
      );
    } else {
      setState(() => _showSettings = true);
    }
  }

  void _closeSettings() => setState(() => _showSettings = false);

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      appBar: isMobile
          ? AppBar(
              title: Text(_titles[_selectedIndex]),
              backgroundColor: AppColors.darkCharcoal,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.tune_outlined),
                  color: Colors.white54,
                  onPressed: _openSettings,
                  tooltip: 'Settings',
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? AdminDrawer(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onItemTapped,
              onSettingsTap: _openSettings,
            )
          : null,
      body: Stack(
        children: [
          Row(
            children: [
              if (!isMobile)
                AdminNavRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  onSettingsTap: _openSettings,
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!isMobile) _buildTopBar(),
                    Expanded(child: _pages[_selectedIndex]),
                  ],
                ),
              ),
            ],
          ),
          if (_showSettings && !isMobile) _buildSettingsOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.softBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            _titles[_selectedIndex],
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedText,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            color: AppColors.darkCharcoal,
            onPressed: _openSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOverlay() {
    return Positioned.fill(
      child: Row(
        children: [
          const SizedBox(width: _navRailWidth),
          Container(
            width: _panelWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: AppColors.softBorder)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(4, 0)),
              ],
            ),
            child: Column(
              children: [
                _buildPanelHeader(),
                const Expanded(child: AdminAccountSettingsPage()),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _closeSettings,
              child: Container(color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.softBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.darkCharcoal,
            onPressed: _closeSettings,
          ),
        ],
      ),
    );
  }
}

class _SettingsShell extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;

  const _SettingsShell({required this.child, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.softBorder)),
          ),
          child: Row(
            children: [
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.darkCharcoal,
                onPressed: onClose,
              ),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
