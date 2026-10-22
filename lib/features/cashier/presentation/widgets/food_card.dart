import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/food_image.dart';

class FoodCard extends StatefulWidget {
  final Map<String, dynamic> food;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final bool isInCart;
  final int quantity;

  const FoodCard({
    super.key,
    required this.food,
    required this.onAdd,
    this.onRemove,
    this.onIncrease,
    this.onDecrease,
    this.isInCart = false,
    this.quantity = 0,
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final price = (widget.food['price'] as num?)?.toDouble() ?? 0.0;
    final categoryName = widget.food['category_name'] ?? widget.food['category'] ?? 'Pastil';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isInCart ? AppColors.goldenYellow : AppColors.softBorder,
            width: widget.isInCart ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkCharcoal.withValues(alpha: widget.isInCart ? 0.08 : 0.04),
              blurRadius: widget.isInCart ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Food Image Header
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
                      color: AppColors.darkCharcoal.withValues(alpha: 0.04),
                    ),
                  // Availability or category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 130),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? AppColors.surfaceWhite.withValues(alpha: 0.92)
                            : AppColors.brandRed.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        isAvailable ? categoryName : 'Sold Out',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isAvailable ? AppColors.darkCharcoal : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body (Title, Price, Stepper / Add button)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 32,
                    child: Text(
                      widget.food['name'] ?? 'Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.darkCharcoal,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkCharcoal,
                      fontSize: 14,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Action Button or Stepper
                  if (widget.isInCart && widget.quantity > 0)
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.goldenYellow, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: widget.onDecrease ?? widget.onRemove,
                            icon: const Icon(LucideIcons.minus, size: 14, color: AppColors.darkCharcoal),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Decrease',
                          ),
                          Text(
                            '${widget.quantity}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkCharcoal,
                            ),
                          ),
                          IconButton(
                            onPressed: widget.onIncrease ?? widget.onAdd,
                            icon: const Icon(LucideIcons.plus, size: 14, color: AppColors.darkCharcoal),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            tooltip: 'Increase',
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 32,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isAvailable
                            ? () {
                                _controller.forward().then((_) => _controller.reverse());
                                widget.onAdd();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAvailable
                              ? AppColors.goldenYellow
                              : AppColors.disabled,
                          foregroundColor: AppColors.darkCharcoal,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isAvailable ? AppColors.goldenYellow : AppColors.softBorder,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.plus,
                              size: 13,
                              color: isAvailable ? AppColors.darkCharcoal : Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAvailable ? 'Add to Dish' : 'Sold Out',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isAvailable ? AppColors.darkCharcoal : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
