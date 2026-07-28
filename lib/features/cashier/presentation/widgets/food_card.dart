import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/food_image.dart';

class FoodCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final bool isInCart;

  const FoodCard({
    super.key,
    required this.food,
    required this.onAdd,
    this.onRemove,
    this.isInCart = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = food['availability'] == 'available' || food['isAvailable'] == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isInCart ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isInCart ? AppColors.goldenYellow : AppColors.softBorder,
          width: isInCart ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: isAvailable ? onAdd : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: isAvailable ? 1.0 : 0.4,
                    child: FoodImage(food: food),
                  ),
                  if (isInCart)
                    Container(
                      color: AppColors.goldenYellow.withValues(alpha: 0.15),
                    ),
                  if (!isAvailable)
                    Container(
                      color: Colors.white.withValues(alpha: 0.5),
                      child: const Center(
                        child: Text(
                          'Not Available',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            backgroundColor: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Opacity(
              opacity: isAvailable ? 1.0 : 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      food['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      food['category_name'] ?? food['category'] ?? 'Category',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${food['price'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandRed,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
