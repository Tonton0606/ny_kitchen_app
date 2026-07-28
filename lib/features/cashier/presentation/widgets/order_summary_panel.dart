import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'order_item_widget.dart';

class OrderSummaryPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in orderItems) {
      subtotal += (item['food']['price'] as double) * (item['quantity'] as int);
    }
    double discount = 0;
    double total = subtotal - discount;

    return Container(
      width: 350,
      color: const Color(0xFFF8F6F0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.softBorder)),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/branding/ny_kitchen_emblem.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('N.Y Kitchen', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkCharcoal)),
                    Text('Order Receipt', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                  ],
                ),
                const Spacer(),
                Text(
                  '#$orderId',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.5),
                ),
                if (onCollapse != null) ...[
                  const SizedBox(width: 2),
                  InkWell(
                    onTap: onCollapse,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.softBorder.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.chevron_right, size: 16, color: AppColors.mutedText),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: orderItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.softBorder.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.receipt_long_outlined, size: 32, color: AppColors.mutedText),
                        ),
                        const SizedBox(height: 16),
                        const Text('No items in order', style: TextStyle(color: AppColors.mutedText, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Tap a food item to start', style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 28),
                            const Expanded(child: Text('Item', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.5))),
                            Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                          itemCount: orderItems.length,
                          separatorBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            child: CustomPaint(
                              painter: _DottedLinePainter(),
                              child: const SizedBox(height: 1, width: double.infinity),
                            ),
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
                    ],
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.softBorder)),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Subtotal', subtotal, bold: false),
                const SizedBox(height: 6),
                _buildSummaryRow('Discount', -discount, color: AppColors.success),
                const SizedBox(height: 6),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: CustomPaint(
                    painter: _DottedLinePainter(),
                    child: const SizedBox(height: 1, width: double.infinity),
                  ),
                ),
                _buildSummaryRow('Total', total, bold: true, large: true),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: orderItems.isEmpty ? null : onClear,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.brandRed,
                          side: BorderSide(color: AppColors.brandRed.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Void', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: orderItems.isEmpty ? null : onCheckout,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: AppColors.darkCharcoal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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

  Widget _buildSummaryRow(String label, double amount, {bool bold = false, bool large = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.darkCharcoal : AppColors.mutedText,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            fontSize: large ? 18 : 13,
          ),
        ),
        Text(
          '₱${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: color ?? (bold ? AppColors.darkCharcoal : AppColors.mutedText),
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            fontSize: large ? 18 : 13,
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
      ..color = AppColors.softBorder.withValues(alpha: 0.7)
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
