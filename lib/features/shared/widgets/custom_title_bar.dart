import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';

class CustomTitleBar extends StatelessWidget {
  final Widget? title;

  const CustomTitleBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return const SizedBox.shrink(); // Hide on mobile/web
    }

    return Container(
      height: 40,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onDoubleTap: () async {
                if (await windowManager.isFullScreen()) {
                  await windowManager.setFullScreen(false);
                } else if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: DragToMoveArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child:
                      title ??
                      const Text(
                        'N.Y Kitchen POS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ),
          ),
          const WindowButtons(),
        ],
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.remove,
          tooltip: 'Minimize',
          onPressed: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: Icons.crop_square,
          tooltip: 'Maximize',
          onPressed: () async {
            if (await windowManager.isFullScreen()) {
              await windowManager.setFullScreen(false);
            } else if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: Icons.close,
          tooltip: 'Close',
          isClose: true,
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color iconColor;

    if (_isHovered) {
      if (widget.isClose) {
        bgColor = AppColors.brandRed;
        iconColor = Colors.white;
      } else {
        bgColor = AppColors.softBorder.withValues(alpha: 0.6);
        iconColor = AppColors.darkCharcoal;
      }
    } else {
      bgColor = Colors.transparent;
      iconColor = AppColors.darkCharcoal;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppDesignTokens.motionFast,
          width: 46,
          height: 40,
          alignment: Alignment.center,
          color: bgColor,
          child: Icon(
            widget.icon,
            size: 16,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
