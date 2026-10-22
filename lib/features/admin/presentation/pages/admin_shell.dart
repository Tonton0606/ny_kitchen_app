import 'package:flutter/material.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/guarded_route.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/utils/responsive.dart';
import '../widgets/navigation/admin_nav_rail.dart';
import '../widgets/navigation/admin_drawer.dart';
import 'admin_dashboard_page.dart';
import 'sales_reports_page.dart';
import 'food_management_page.dart';
import 'account_management_page.dart';
import 'activity_logs_page.dart';
import 'backup_restore_page.dart';
import 'admin_account_settings_page.dart';
import '../../../shared/widgets/app_status_strip.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  bool _showSettings = false;

  bool _isNavExpanded = false;
  static const double _panelWidth = 500.0;

  late final List<Widget> _pages = [
    AdminDashboardPage(
      onNavigate: _onItemTapped,
      onSettingsTap: _openSettings,
    ),
    const SalesReportsPage(),
    const FoodManagementPage(),
    const AccountManagementPage(),
    const ActivityLogsPage(),
    const BackupRestorePage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Sales Reports',
    'Food Management',
    'Account Management',
    'Activity Logs',
    'Backup & Restore',
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

    return GuardedRoute(
      allowedRoles: const ['admin'],
      child: Scaffold(
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
                    isExpanded: _isNavExpanded,
                    onToggleExpand: (expanded) {
                      setState(() => _isNavExpanded = expanded);
                    },
                    onDestinationSelected: _onItemTapped,
                    onSettingsTap: _openSettings,
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isMobile) _buildTopBar(),
                      Expanded(child: _pages[_selectedIndex]),
                    ],
                  ),
                ),
              ],
            ),
            if (!isMobile)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_showSettings,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _showSettings ? 1.0 : 0.0,
                    child: _buildSettingsOverlay(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return AppStatusStrip(
      title: _titles[_selectedIndex],
      onSettingsTap: _openSettings,
    );
  }

  Widget _buildSettingsOverlay() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _closeSettings,
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),
        ),
        Container(
          width: _panelWidth,
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            border: Border(left: BorderSide(color: AppColors.softBorder)),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(-4, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildPanelHeader(),
              const Expanded(child: AdminAccountSettingsPage()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPanelHeader() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.softBorder)),
      ),
      child: Row(
        children: [
          const Text(
            'Settings',
            style: AppTypography.heading,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.darkCharcoal,
            tooltip: 'Close settings',
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
                tooltip: 'Close settings',
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
