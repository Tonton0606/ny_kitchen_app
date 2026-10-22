import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/session/session_manager.dart';
import '../../auth/presentation/pages/login_page.dart';

/// Standard Confirmation Dialog conforming strictly to UI_PRINCIPLES.md:
/// - Clean 12px surface with 1px softBorder
/// - Cancel as default focus (autofocus: true)
/// - Typography roles (Space Grotesk heading/button, Inter body)
/// - No arbitrary colored container boxes
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String consequenceText;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.consequenceText,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = true,
    this.icon,
  });

  /// Helper static method to show a confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String consequenceText,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = true,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        consequenceText: consequenceText,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  /// Unified clean logout confirmation dialog conforming to UI_PRINCIPLES.md
  static void showLogoutDialog(BuildContext context, {required bool isAdmin}) {
    showDialog(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Confirm Logout',
        consequenceText: isAdmin
            ? 'Are you sure you want to end your administrative session and log out?'
            : 'Are you sure you want to end your shift and log out? Unsaved orders should be checked out first.',
        confirmText: 'Logout',
        cancelText: 'Cancel',
        isDestructive: true,
        icon: LucideIcons.log_out,
        onConfirm: () {
          SessionManager().clearSession();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        side: const BorderSide(color: AppColors.softBorder, width: 1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: isDestructive ? AppColors.brandRed : AppColors.darkCharcoal,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.heading,
            ),
          ),
        ],
      ),
      content: Text(
        consequenceText,
        style: AppTypography.bodyMuted,
      ),
      actions: [
        // Cancel is ALWAYS default focus
        OutlinedButton(
          autofocus: true,
          onPressed: () {
            if (onCancel != null) {
              onCancel!();
            } else {
              Navigator.of(context).pop(false);
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.softBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            cancelText,
            style: AppTypography.button.copyWith(color: AppColors.darkCharcoal),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive ? AppColors.brandRed : AppColors.goldenYellow,
            foregroundColor: isDestructive ? Colors.white : AppColors.darkCharcoal,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            confirmText,
            style: AppTypography.button.copyWith(
              color: isDestructive ? Colors.white : AppColors.darkCharcoal,
            ),
          ),
        ),
      ],
    );
  }
}
