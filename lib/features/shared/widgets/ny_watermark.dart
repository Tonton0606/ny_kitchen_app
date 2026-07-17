import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class NyWatermark extends StatelessWidget {
  const NyWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Transform.rotate(
            angle: -0.15,
            child: Opacity(
              opacity: 0.03,
              child: Text(
                'NY',
                style: TextStyle(
                  color: AppColors.darkCharcoal,
                  fontSize: 280,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
