import 'package:flutter/material.dart';
import 'order_item_widget.dart';

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
    double subtotal = 0;
    for (var item in orderItems) {
      subtotal += (item['food']['price'] as double) * (item['quantity'] as int);
    }
    double discount = 0; // Mock discount
    double tax = subtotal * 0.12; // Mock 12% tax
    double total = subtotal - discount + tax;

    return Container(
      width: 350,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.surface,
            child:  Row(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                SizedBox(width: 8),
                Text(
                  'Current Order',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: orderItems.isEmpty
                ?  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart,
                          size: 64,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No items in order',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: orderItems.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow(context, 'Subtotal', subtotal),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Discount', -discount, isDiscount: true),
                const SizedBox(height: 8),
                _buildSummaryRow(context, 'Tax (12%)', tax),
                Divider(
                  height: 24,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _buildSummaryRow(context, 'Total', total, isTotal: true),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: orderItems.isEmpty ? null : onClear,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: orderItems.isEmpty ? null : onCheckout,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 20 : 14,
          ),
        ),
        Text(
          '₱${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: isDiscount
                ? Colors.green
                : (isTotal
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface),
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 20 : 14,
          ),
        ),
      ],
    );
  }
}
