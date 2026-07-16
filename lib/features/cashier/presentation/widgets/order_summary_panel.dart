import 'package:flutter/material.dart';
import 'order_item_widget.dart';
import '../../../shared/widgets/state_placeholders.dart';

class OrderSummaryPanel extends StatelessWidget {
  final List<Map<String, dynamic>> orderItems;
  final Function(int) onIncrease;
  final Function(int) onDecrease;
  final Function(int) onRemove;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  const OrderSummaryPanel({
    super.key,
    required this.orderItems,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onClear,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    double subtotal = 0;
    for (var item in orderItems) {
      subtotal += (item['food']['price'] as double) * (item['quantity'] as int);
    }
    double discount = 0; // Mock discount
    double tax = subtotal * 0.12; // Mock 12% tax
    double total = subtotal - discount + tax;

    return Container(
      width: 350,
      color: cs.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.shopping_bag_outlined, color: cs.onSurface),
                const SizedBox(width: 8),
                Text('Current Order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface),
                ),
              ],
            ),
          ),
          Expanded(
            child: orderItems.isEmpty
                ? StatePlaceholders.empty(
                    message: 'Your order is empty. Tap a menu item to add it.',
                    icon: Icons.shopping_bag_outlined,
                    context: context,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: orderItems.length,
                    separatorBuilder: (context, index) => Divider(color: cs.outlineVariant),
                    itemBuilder: (context, index) {
                      return OrderItemWidget(
                        item: orderItems[index],
                        onIncrease: () => onIncrease(index),
                        onDecrease: () => onDecrease(index),
                        onRemove: () => onRemove(index),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: cs.surface,
            ),
            child: Column(
              children: [
                Divider(height: 1, color: cs.outlineVariant),
                const SizedBox(height: 16),
                _buildSummaryRow(context, 'Subtotal', subtotal),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Discount', -discount, isDiscount: true),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Tax (12%)', tax),
                Divider(height: 24, color: cs.outlineVariant),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildSummaryRow(context, 'Total', total, isTotal: true),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: orderItems.isEmpty ? null : onClear,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.error,
                          side: BorderSide(color: cs.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: orderItems.isEmpty ? null : onCheckout,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
          style: isTotal
              ? TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface)
              : textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        Text('₱${amount.abs().toStringAsFixed(2)}',
          style: isTotal
              ? TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onSurface)
              : textTheme.bodyMedium?.copyWith(
                  color: isDiscount ? cs.tertiary : cs.onSurface,
                ),
        ),
      ],
    );
  }
}
