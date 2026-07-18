import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/pages/login_page.dart';

class AdminNavRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onSettingsTap;

  const AdminNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.onSettingsTap,
  });

  @override
  State<AdminNavRail> createState() => _AdminNavRailState();
}

class _AdminNavRailState extends State<AdminNavRail> {
  bool _isExtended = false;

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
    final bool isWindows = Theme.of(context).platform == TargetPlatform.windows;

    if (isWindows) {
      return NavigationRail(
        extended: _isExtended,
        minWidth: 76.0,
        minExtendedWidth: 240.0,
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
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
        selectedLabelTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.goldenYellow,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
        indicatorColor: AppColors.goldenYellow.withValues(alpha: 0.25),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        groupAlignment: -0.25,
        leading: _buildLeading(context, isWindows),
        trailing: _buildTrailing(context, isWindows),
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
      );
    }

    // Android/Non-Windows implementation (100% unchanged)
    return SizedBox(
      width: 76,
      child: NavigationRail(
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
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
        leading: _buildLeading(context, isWindows),
        trailing: _buildTrailing(context, isWindows),
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

  Widget _buildLeading(BuildContext context, bool isWindows) {
    if (!isWindows) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0, top: 12.0),
        child: GestureDetector(
          onTap: widget.onSettingsTap,
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
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: _isExtended ? 16.0 : 8.0,
        vertical: 12.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: _isExtended ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: widget.onSettingsTap,
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
              if (_isExtended)
                IconButton(
                  icon: const Icon(
                    Symbols.menu_open,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExtended = !_isExtended;
                    });
                  },
                ),
            ],
          ),
          if (!_isExtended) ...[
            const SizedBox(height: 12),
            IconButton(
              icon: const Icon(
                Symbols.menu,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() {
                  _isExtended = !_isExtended;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrailing(BuildContext context, bool isWindows) {
    if (!isWindows) {
      return Expanded(
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
      );
    }

    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _isExtended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Divider(
              height: 1,
              color: Colors.white12,
              indent: _isExtended ? 24 : 16,
              endIndent: _isExtended ? 24 : 16,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.only(
                bottom: 20.0,
                left: _isExtended ? 16.0 : 0.0,
                right: _isExtended ? 16.0 : 0.0,
              ),
              child: _isExtended
                  ? InkWell(
                      onTap: () => _showLogoutDialog(context),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.logout_rounded,
                              color: Colors.white54,
                              weight: 500,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : IconButton(
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
    );
  }
}
