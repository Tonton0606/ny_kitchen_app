import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double borderRadius;
  final double fontSize;

  const AppLogo({
    super.key,
    this.size = 48.0,
    this.borderRadius = 12.0,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          'NY',
          style: TextStyle(
            color: AppColors.darkCharcoal,
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
