import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class FoodImage extends StatelessWidget {
  final Map<String, dynamic> food;
  final double height;

  const FoodImage({super.key, required this.food, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final name = food['name'] as String;
    final isAvailable = food['isAvailable'] as bool;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          food['image'],
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(name);
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(name),
        ),
        if (!isAvailable)
          Container(
            color: Colors.white.withValues(alpha: 0.6),
            child: Center(
              child: Text(
                'Unavailable',
                style: TextStyle(
                  color: AppColors.brandRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(String name) {
    return Container(
      color: AppColors.goldenYellow.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.darkCharcoal,
            fontSize: 36,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
