import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';

/// Primary Call-To-Action Button with modern tactile 3D press physics.
/// Conforms to 48px/56px touch target standards, 8px radius, and high contrast.
class AppPrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isLarge; // 56px height for primary POS actions (e.g. Add, Charge)
  final double? width;

  const AppPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isLarge = false,
    this.width,
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double height = widget.isLarge
        ? AppDesignTokens.primaryActionTouchTarget
        : AppDesignTokens.minTouchTarget;
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return SizedBox(
      width: widget.width,
      height: height,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, _isPressed ? 1.5 : 0, 0),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.goldenYellow : AppColors.disabled,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: _isPressed ? AppColors.goldDeep : AppColors.goldTactileEdge,
                      offset: Offset(0, _isPressed ? 1.0 : 2.5),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCharcoal),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: AppColors.darkCharcoal),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Secondary Outlined Button with subtle tactile 3D border physics.
class AppSecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLarge;
  final double? width;

  const AppSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLarge = false,
    this.width,
  });

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double height = widget.isLarge
        ? AppDesignTokens.primaryActionTouchTarget
        : AppDesignTokens.minTouchTarget;
    final bool isEnabled = widget.onPressed != null;

    return SizedBox(
      width: widget.width,
      height: height,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, _isPressed ? 1.0 : 0, 0),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.surfaceWhite : AppColors.creamBackground,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            border: Border.all(
              color: isEnabled ? AppColors.softBorder : AppColors.disabled,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: isEnabled ? AppColors.darkCharcoal : AppColors.disabled,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? AppColors.darkCharcoal : AppColors.disabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destructive Action Button (Red fill, white text, 3D bottom edge).
class AppDestructiveButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double? width;

  const AppDestructiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.width,
  });

  @override
  State<AppDestructiveButton> createState() => _AppDestructiveButtonState();
}

class _AppDestructiveButtonState extends State<AppDestructiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    const double height = AppDesignTokens.minTouchTarget;
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    return SizedBox(
      width: widget.width,
      height: height,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          transform: Matrix4.translationValues(0, _isPressed ? 1.5 : 0, 0),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.brandRed : AppColors.disabled,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: AppColors.destructiveTactileEdge,
                      offset: Offset(0, _isPressed ? 1.0 : 2.5),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
