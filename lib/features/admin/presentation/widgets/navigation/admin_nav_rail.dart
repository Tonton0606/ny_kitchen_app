import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';

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
    AppConfirmDialog.showLogoutDialog(context, isAdmin: true);
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: LucideIcons.layout_dashboard, label: 'Dashboard'),
      _NavItem(icon: LucideIcons.trending_up,     label: 'Sales Reports'),
      _NavItem(icon: LucideIcons.utensils,        label: 'Food Management'),
      _NavItem(icon: LucideIcons.users,           label: 'Account Management'),
      _NavItem(icon: LucideIcons.clipboard_list,  label: 'Activity Logs'),
      _NavItem(icon: LucideIcons.database_backup, label: 'Backup & Restore'),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: widget.isExpanded ? 220 : 80,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(
          right: BorderSide(color: AppColors.softBorder, width: 1),
        ),
      ),
      child: OverflowBox(
        minWidth: widget.isExpanded ? 220 : 80,
        maxWidth: widget.isExpanded ? 220 : 80,
        alignment: Alignment.topLeft,
        child: Column(
          children: [
            // Header: Logo + Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.softBorder, width: 1),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/branding/ny_kitchen_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: AppColors.goldenYellow,
                          child: const Center(
                            child: Text(
                              'NY',
                              style: TextStyle(
                                color: AppColors.darkCharcoal,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isExpanded) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NY Kitchen',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.darkCharcoal,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Admin Portal',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.mutedBrown,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Tooltip(
              message: widget.isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
              waitDuration: const Duration(milliseconds: 300),
              child: IconButton(
                icon: Icon(
                  widget.isExpanded ? Symbols.chevron_left_rounded : Symbols.chevron_right_rounded,
                  color: AppColors.darkCharcoal,
                ),
                onPressed: () => widget.onToggleExpand(!widget.isExpanded),
              ),
            ),

            const Divider(color: AppColors.softBorder, height: 1, indent: 12, endIndent: 12),
            const SizedBox(height: 10),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = widget.selectedIndex == index;

                final navButton = Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => widget.onDestinationSelected(index),
                      child: AnimatedContainer(
                        duration: AppDesignTokens.motionFast,
                        padding: EdgeInsets.symmetric(
                          horizontal: widget.isExpanded ? 16 : 0,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.goldenYellow : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: widget.isExpanded
                            ? Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? AppColors.darkCharcoal
                                        : AppColors.darkCharcoal.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.darkCharcoal,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  item.icon,
                                  size: 22,
                                  color: isSelected
                                      ? AppColors.darkCharcoal
                                      : AppColors.darkCharcoal.withValues(alpha: 0.7),
                                ),
                              ),
                      ),
                    ),
                  ),
                );

                if (!widget.isExpanded) {
                  return Tooltip(
                    message: item.label,
                    waitDuration: const Duration(milliseconds: 250),
                    child: navButton,
                  );
                }
                return navButton;
              },
            ),
          ),

          // Pinned Role & Admin Badge / Profile Chip
          Tooltip(
            message: 'Administrator (Full System Access)',
            waitDuration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              padding: EdgeInsets.symmetric(
                horizontal: widget.isExpanded ? 10 : 0,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.creamBackground,
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                border: Border.all(color: AppColors.softBorder, width: 1),
              ),
              child: widget.isExpanded
                  ? Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.inkBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'ADMINISTRATOR',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.darkCharcoal,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Full System Access',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.inkBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(
                        LucideIcons.shield_check,
                        size: 18,
                        color: AppColors.inkBlue,
                      ),
                    ),
            ),
          ),

          const Divider(color: AppColors.softBorder, height: 1, indent: 12, endIndent: 12),

          // Logout Action
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Tooltip(
              message: 'Logout',
              waitDuration: const Duration(milliseconds: 250),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showLogoutDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: widget.isExpanded
                        ? const Row(
                            children: [
                              Icon(LucideIcons.log_out, size: 18, color: AppColors.brandRed),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Logout',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.brandRed,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Icon(LucideIcons.log_out, size: 20, color: AppColors.brandRed),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
