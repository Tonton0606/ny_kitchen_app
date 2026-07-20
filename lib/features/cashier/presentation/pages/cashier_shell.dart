import 'package:flutter/material.dart';
import 'package:ny_kitchen_app/features/auth/presentation/widgets/guarded_route.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import 'home_page.dart';
import 'orders_page.dart';
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
  bool _showSettings = false;
  bool _isNavExpanded = false;

  static const double _navRailWidth = 76.0;
  static const double _panelWidth = 380.0;

  final List<Widget> _pages = const [
    CashierHomePage(),
    OrdersPage(),
    TransactionHistoryPage(),
  ];

  final List<String> _titles = [
    'Cashier',
    'Active Orders',
    'Transaction History',
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
          initialChildSize: 0.85,
          builder: (_, scrollController) => _SettingsShell(
            onClose: () => Navigator.pop(context),
            child: const AccountSettingsPage(),
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
      allowedRoles: const ['cashier', 'admin'],
      child: Scaffold(
        body: Stack(
          children: [
            Responsive(
              mobile: _buildMobileLayout(),
              tablet: _buildDesktopLayout(),
              desktop: _buildDesktopLayout(),
            ),
            if (_showSettings && !isMobile) _buildSettingsOverlay(),
          ],
        ),
        bottomNavigationBar: isMobile
            ? CashierBottomNav(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemTapped,
              )
            : null,
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTopBar(isMobile: true),
        Expanded(child: _pages[_selectedIndex]),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        CashierNavRail(
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
            children: [
              _buildTopBar(isMobile: false),
              Expanded(child: _pages[_selectedIndex]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar({required bool isMobile}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isMobile ? AppColors.darkCharcoal : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isMobile ? Colors.white12 : AppColors.softBorder,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            _titles[_selectedIndex],
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              fontFamily: 'serif',
              letterSpacing: 0.1,
              color: isMobile ? Colors.white : AppColors.mutedText,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            color: isMobile ? Colors.white54 : AppColors.darkCharcoal,
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
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(4, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPanelHeader(),
                const Expanded(child: AccountSettingsPage()),
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
