import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/pages/login_page.dart';
import '../../../../../core/session/session_manager.dart';

class AdminNavRail extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback? onSettingsTap;

  final bool isExpanded;
  final ValueChanged<bool> onToggleExpand;

  const AdminNavRail({
    super.key,
    required this.selectedIndex,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onDestinationSelected,
    this.onSettingsTap,
  });

  @override
  State<AdminNavRail> createState() => _AdminNavRailState();
}

class _AdminNavRailState extends State<AdminNavRail> {

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Symbols.logout_rounded, color: AppColors.brandRed, size: 24, weight: 500),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: 14, color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              SessionManager().clearSession();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Symbols.dashboard_rounded,      label: 'Dashboard'),
      _NavItem(icon: Symbols.trending_up_rounded,    label: 'Sales Reports'),
      _NavItem(icon: Symbols.menu_book_rounded,      label: 'Food Management'),
      _NavItem(icon: Symbols.badge_rounded,          label: 'Account Management'),
      _NavItem(icon: Symbols.assignment_rounded,     label: 'Activity Logs'),
      _NavItem(icon: Symbols.backup_rounded,         label: 'Backup & Restore'),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: widget.isExpanded ? 220 : 80,
      color: AppColors.darkCharcoal,
      child: Column(
        children: [
          // Logo / avatar + Toggle button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.goldenYellow,
                  child: const Text(
                    'NY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (widget.isExpanded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('NY Kitchen', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Admin Portal', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          IconButton(
            icon: Icon(
              widget.isExpanded ? Symbols.chevron_left_rounded : Symbols.chevron_right_rounded,
              color: Colors.white70,
            ),
            onPressed: () => widget.onToggleExpand(!widget.isExpanded),
          ),

          const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = widget.selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => widget.onDestinationSelected(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.goldenYellow.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: widget.isExpanded
                            ? Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    weight: 500,
                                    size: 24,
                                    color: isSelected ? AppColors.goldenYellow : Colors.white54,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected ? AppColors.goldenYellow : Colors.white54,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    weight: 500,
                                    size: 24,
                                    color: isSelected ? AppColors.goldenYellow : Colors.white54,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout
          const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _showLogoutDialog(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: widget.isExpanded
                      ? const Row(
                          children: [
                            Icon(Symbols.logout_rounded, weight: 500, size: 24, color: Colors.white38),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Logout',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, color: Colors.white38),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Symbols.logout_rounded, weight: 500, size: 24, color: Colors.white38),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
