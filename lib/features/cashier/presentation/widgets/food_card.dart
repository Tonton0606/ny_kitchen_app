import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/food_image.dart';

class FoodCard extends StatefulWidget {
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
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = widget.food['availability'] == 'available' || widget.food['isAvailable'] == true;

    return GestureDetector(
      onTapDown: isAvailable ? (_) => _controller.forward() : null,
      onTapUp: isAvailable ? (_) {
        _controller.reverse();
        widget.onAdd();
      } : null,
      onTapCancel: isAvailable ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: widget.isInCart ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: widget.isInCart ? AppColors.goldenYellow : AppColors.softBorder,
              width: widget.isInCart ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Opacity(
                      opacity: isAvailable ? 1.0 : 0.4,
                      child: FoodImage(food: widget.food),
                    ),
                    if (widget.isInCart)
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
                        widget.food['name'],
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
                        widget.food['category_name'] ?? widget.food['category'] ?? 'Category',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₱${widget.food['price'].toStringAsFixed(2)}',
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
      ),
    );
  }
}
