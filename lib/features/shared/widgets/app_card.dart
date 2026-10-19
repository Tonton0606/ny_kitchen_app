import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';

/// Standard Flat Surface Card conforming to the 12px radius and 1px softBorder rule.
/// Zero blur, zero heavy shadows for maximum POS rendering speed.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final bool isInteractive;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDesignTokens.space16),
    this.onTap,
    this.backgroundColor = AppColors.surfaceWhite,
    this.borderColor = AppColors.softBorder,
    this.borderWidth = 1.0,
    this.isInteractive = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: borderColor,
      width: borderWidth,
    );

    if (onTap != null || isInteractive) {
      return Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          hoverColor: AppColors.pageBackground,
          splashColor: AppColors.darkCharcoal.withValues(alpha: 0.05),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
              border: border,
            ),
            child: child,
          ),
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: border,
      ),
      child: child,
    );
  }
}
