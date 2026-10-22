import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../core/theme/app_colors.dart';
import 'order_item_widget.dart';

class OrderSummaryPanel extends StatefulWidget {
  final List<Map<String, dynamic>> orderItems;
  final String orderId;
  final Function(int) onIncrease;
  final Function(int) onDecrease;
  final Function(int) onRemove;
  final VoidCallback onClear;
  final VoidCallback onCheckout;
  final VoidCallback? onCollapse;

  const OrderSummaryPanel({
    super.key,
    required this.orderId,
    required this.orderItems,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onClear,
    required this.onCheckout,
    this.onCollapse,
  });

  @override
  State<OrderSummaryPanel> createState() => _OrderSummaryPanelState();
}

class _OrderSummaryPanelState extends State<OrderSummaryPanel> {


  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in widget.orderItems) {
      final price = (item['food']['price'] as num).toDouble();
      final qty = item['quantity'] as int;
      subtotal += price * qty;
    }
    const double discount = 0;
    final double total = subtotal - discount;

    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(left: BorderSide(color: AppColors.softBorder, width: 1)),
      ),
      child: Column(
        children: [
          // Header with Order # and Dine-In badge
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.softBorder, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Order #${widget.orderId}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkCharcoal,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.pencil, size: 14, color: AppColors.mutedBrown),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.goldenYellow.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.goldenYellow.withValues(alpha: 0.5), width: 1),
                            ),
                            child: const Text(
                              'Dine In Only',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Live Terminal Cart',
                            style: TextStyle(fontSize: 11, color: AppColors.mutedBrown),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.onCollapse != null)
                  IconButton(
                    onPressed: widget.onCollapse,
                    icon: const Icon(LucideIcons.panel_right_close, size: 18, color: AppColors.mutedBrown),
                    tooltip: 'Collapse Cart',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),

          // Cart Items List
          Expanded(
            child: widget.orderItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.creamBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.softBorder, width: 1),
                          ),
                          child: const Icon(
                            LucideIcons.shopping_bag,
                            size: 28,
                            color: AppColors.mutedBrown,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No items in cart',
                          style: TextStyle(
                            color: AppColors.darkCharcoal,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Select dishes from the menu to add',
                          style: TextStyle(color: AppColors.mutedBrown, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                    itemCount: widget.orderItems.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.softBorder,
                    ),
                    itemBuilder: (context, index) {
                      return OrderItemWidget(
                        item: widget.orderItems[index],
                        onIncrease: () => widget.onIncrease(index),
                        onDecrease: () => widget.onDecrease(index),
                        onRemove: () => widget.onRemove(index),
                      );
                    },
                  ),
          ),

          // Bottom Summary & Payment Section
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(top: BorderSide(color: AppColors.softBorder, width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Subtotal & Discount
                _buildSummaryRow('Subtotal', subtotal, bold: false),
                const SizedBox(height: 6),
                _buildSummaryRow('Tax / Service', discount, bold: false),
                const SizedBox(height: 10),

                // Dotted line
                CustomPaint(
                  painter: _DottedLinePainter(),
                  child: const SizedBox(height: 1, width: double.infinity),
                ),
                const SizedBox(height: 10),

                // Total Amount
                _buildSummaryRow('Total Amount', total, bold: true, large: true),
                const SizedBox(height: 16),

                // Payment Method (Cash Only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.goldenYellow, width: 1.5),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.banknote, size: 18, color: AppColors.darkCharcoal),
                      SizedBox(width: 8),
                      Text(
                        'Cash Payment Only',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkCharcoal,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Actions: Void + Place Order
                Row(
                  children: [
                    if (widget.orderItems.isNotEmpty) ...[
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: widget.onClear,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandRed,
                            side: BorderSide(color: AppColors.brandRed.withValues(alpha: 0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          child: const Icon(LucideIcons.trash, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: widget.orderItems.isEmpty
                                ? null
                                : const [
                                    BoxShadow(
                                      color: AppColors.goldTactileEdge,
                                      offset: Offset(0, 2),
                                      blurRadius: 0,
                                      spreadRadius: 0,
                                    ),
                                  ],
                          ),
                          child: ElevatedButton(
                            onPressed: widget.orderItems.isEmpty ? null : widget.onCheckout,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldenYellow,
                              foregroundColor: AppColors.darkCharcoal,
                              disabledBackgroundColor: AppColors.disabled,
                              disabledForegroundColor: AppColors.darkCharcoal.withValues(alpha: 0.4),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Place Order',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (widget.orderItems.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '• ₱${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ],
                            ),
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



  Widget _buildSummaryRow(String label, double amount, {bool bold = false, bool large = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.darkCharcoal : AppColors.mutedBrown,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: large ? 16 : 13,
          ),
        ),
        Text(
          '₱${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: bold ? AppColors.darkCharcoal : AppColors.mutedBrown,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            fontSize: large ? 18 : 13,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.softBorder
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
