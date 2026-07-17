import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class OrderItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const OrderItemWidget({
    super.key,
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final food = item['food'];
    final quantity = item['quantity'] as int;
    final price = food['price'] as double;
    final total = price * quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.darkCharcoal,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'x',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  food['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.darkCharcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 28),
              Text(
                '₱${price.toStringAsFixed(2)} ea',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedText,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onDecrease,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.softBorder),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.remove, size: 12, color: AppColors.mutedText),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$quantity',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onIncrease,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, size: 12, color: Colors.black),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.close, size: 12, color: AppColors.brandRed.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
