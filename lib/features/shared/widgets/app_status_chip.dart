import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';

enum AppStatusType {
  success, // Forest green: paid, synced, active, in-stock
  info,    // Ink blue: info, syncing, processing
  warning, // Gold tint: low stock, pending sync, expiring
  error,   // Brand red: voided, locked, disconnected, failed
}

/// Semantic Status Chip adhering to WCAG rules:
/// Always pairs color with an icon and clear label text, with standard 8px radius.
class AppStatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AppStatusType type;
  final bool isCompact;

  const AppStatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.type,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;
    IconData defaultIcon;

    switch (type) {
      case AppStatusType.success:
        bg = AppColors.forest.withValues(alpha: 0.12);
        fg = AppColors.forest;
        border = AppColors.forest.withValues(alpha: 0.35);
        defaultIcon = Icons.check_circle_outline;
        break;
      case AppStatusType.info:
        bg = AppColors.inkBlue.withValues(alpha: 0.12);
        fg = AppColors.inkBlue;
        border = AppColors.inkBlue.withValues(alpha: 0.35);
        defaultIcon = Icons.info_outline;
        break;
      case AppStatusType.warning:
        bg = AppColors.goldTint;
        fg = AppColors.goldInk;
        border = AppColors.goldenYellow;
        defaultIcon = Icons.warning_amber_rounded;
        break;
      case AppStatusType.error:
        bg = AppColors.brandRed.withValues(alpha: 0.10);
        fg = AppColors.brandRed;
        border = AppColors.brandRed.withValues(alpha: 0.35);
        defaultIcon = Icons.error_outline;
        break;
    }

    final effectiveIcon = icon ?? defaultIcon;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(effectiveIcon, size: isCompact ? 12 : 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: fg,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
