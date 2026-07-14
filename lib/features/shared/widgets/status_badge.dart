import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? backgroundColor;

  const StatusBadge({
    super.key,
    required this.text,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = color ?? theme.colorScheme.primary;
    final defaultBgColor =
        backgroundColor ?? defaultColor.withValues(alpha: 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: defaultBgColor,
        borderRadius: BorderRadius.circular(
          12,
        ), // Follows UI guidelines for badges/chips
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: defaultColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
