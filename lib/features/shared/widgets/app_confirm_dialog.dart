import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import 'app_buttons.dart';

/// Standard Destructive Confirmation Dialog conforming strictly to:
/// - Red action button
/// - Plain-language consequence text
/// - Cancel as default focus (autofocus: true)
/// - Flat 12px surface with 1px softBorder
class AppConfirmDialog extends StatelessWidget {
  final String title;
  final String consequenceText;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.consequenceText,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = true,
  });

  /// Helper static method to show the dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String consequenceText,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = true,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: title,
        consequenceText: consequenceText,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive
                  ? AppColors.brandRed.withValues(alpha: 0.12)
                  : AppColors.goldenYellow,
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            child: Icon(
              isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
              color: isDestructive ? AppColors.brandRed : AppColors.darkCharcoal,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.darkCharcoal,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        consequenceText,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.mutedBrown,
          height: 1.45,
        ),
      ),
      actions: [
        // Cancel is ALWAYS default focus
        TextButton(
          autofocus: true,
          onPressed: () {
            if (onCancel != null) {
              onCancel!();
            } else {
              Navigator.of(context).pop(false);
            }
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: AppColors.darkCharcoal,
          ),
          child: Text(
            cancelText,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.darkCharcoal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        isDestructive
            ? AppDestructiveButton(
                text: confirmText,
                onPressed: onConfirm,
              )
            : AppPrimaryButton(
                text: confirmText,
                onPressed: onConfirm,
              ),
      ],
    );
  }
}
