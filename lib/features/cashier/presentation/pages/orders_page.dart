import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/database/repositories/transaction_repository.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_state_placeholders.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  symbol: '₱',
  decimalDigits: 2,
);


class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  // UI Principles: Active queue 'Preparing' is default instead of 'All'
  String _statusFilter = 'Preparing';

  static const _flow = ['Preparing', 'Served'];

  final TransactionRepository _transactionRepo = TransactionRepository();
  List<Map<String, dynamic>> _orders = [];
  Timer? _timer;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final activeTxns = await _transactionRepo.getActiveTransactions();

    List<Map<String, dynamic>> loadedOrders = [];
    for (var txn in activeTxns) {
      final items = await _transactionRepo.getTransactionItems(
        txn['id'] as int,
      );
      final receiptNumber = txn['receipt_number']?.toString() ?? '';
      final parsedTime = DateTime.tryParse(txn['created_at']?.toString() ?? '');
      final formattedTime = parsedTime != null
          ? DateFormat('h:mm a').format(parsedTime)
          : (txn['created_at']?.toString() ?? '');
      loadedOrders.add({
        'id': txn['id'],
        'orderNo': txn['order_number'] != null
            ? '#${txn['order_number']}'
            : receiptNumber,
        'receipt': receiptNumber,
        'status': txn['status'],
        'total': txn['total_amount'],
        'customer': txn['cashier_name'] ?? 'User ${txn['user_id']}',
        'time': formattedTime,
        'items': items
            .map(
              (i) => {
                'name': i['food_name'],
                'qty': i['quantity'],
                'price': i['food_price'],
              },
            )
            .toList(),
        'payment': txn['payment_method'] ?? 'Cash',
        'notes': txn['notes'],
        'orderType': txn['order_type'] ?? 'dine_in',
        'packagingFee': (txn['packaging_fee'] as num?)?.toDouble() ?? 0.0,
      });
    }

    if (!mounted) return;
    setState(() {
      _orders = loadedOrders;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_statusFilter == 'All') return _orders;
    return _orders.where((o) => o['status'] == _statusFilter).toList();
  }

  int get _inProgressCount =>
      _orders.where((o) => o['status'] == 'Preparing').length;

  Future<void> _advanceStatus(Map<String, dynamic> order) async {
    final status = order['status'] as String? ?? '';
    if (status == 'Served') return;

    final currentIdx = _flow.indexOf(status);
    final nextStatus = (currentIdx >= 0 && currentIdx < _flow.length - 1)
        ? _flow[currentIdx + 1]
        : 'Served';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: const BorderSide(color: AppColors.softBorder),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.space8),
              decoration: BoxDecoration(
                color: AppColors.forest.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.forest,
                size: 22,
              ),
            ),
            const SizedBox(width: AppDesignTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Advance Order', style: AppTypography.dialogTitle),
                  const SizedBox(height: 2),
                  Text(order['orderNo'], style: AppTypography.bodyMuted),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.space12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['customer'], style: AppTypography.body),
                        const SizedBox(height: 2),
                        Text(order['time'], style: AppTypography.label),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(order['payment'], style: AppTypography.label),
                      const SizedBox(height: 2),
                      Text(
                        _currencyFormat.format((order['total'] as num?)?.toDouble() ?? 0),
                        style: AppTypography.figure,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppStatusChip(
                  label: order['status'] as String,
                  type: order['status'] == 'Served' ? AppStatusType.success : AppStatusType.warning,
                  icon: order['status'] == 'Served' ? Icons.check_circle_outline : Icons.soup_kitchen_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppDesignTokens.space8),
                  child: Icon(Icons.arrow_forward, size: 16, color: AppColors.mutedSlate),
                ),
                AppStatusChip(
                  label: nextStatus,
                  type: nextStatus == 'Served' ? AppStatusType.success : AppStatusType.warning,
                  icon: nextStatus == 'Served' ? Icons.check_circle_outline : Icons.soup_kitchen_outlined,
                ),
              ],
            ),
            if (order['items'] != null) ...[
              const SizedBox(height: AppDesignTokens.space12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Text('ORDER ITEMS', style: AppTypography.label),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                        child: Column(
                          children: (order['items'] as List).map<Widget>((item) {
                            final itemPrice = (item['price'] as num?)?.toDouble() ?? 0;
                            final itemQty = (item['qty'] as num?)?.toInt() ?? 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Text(
                                    '$itemQty×',
                                    style: AppTypography.figureSmall,
                                  ),
                                  const SizedBox(width: AppDesignTokens.space8),
                                  Expanded(
                                    child: Text(
                                      item['name'],
                                      style: AppTypography.body,
                                    ),
                                  ),
                                  Text(
                                    _currencyFormat.format(itemPrice * itemQty),
                                    style: AppTypography.figureSmall,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          AppSecondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppPrimaryButton(
            text: 'Confirm & $nextStatus',
            icon: Icons.check_circle_outline,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final updatedCount = await _transactionRepo.updateTransactionStatus(
        order['id'],
        nextStatus,
        receiptNumber: order['receipt']?.toString(),
      );
      await _loadOrders();
      if (!mounted) return;
      if (updatedCount == 0) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Order was updated during background sync. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('${order['orderNo']} marked as $nextStatus'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.brandRed),
      );
    }
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final items = order['items'] as List;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: const BorderSide(color: AppColors.softBorder),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.space8),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: AppColors.brandRed,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDesignTokens.space12),
            const Expanded(
              child: Text(
                'Cancel Order',
                style: AppTypography.dialogTitle,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDesignTokens.space12),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.25)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.brandRed, size: 20),
                  SizedBox(width: AppDesignTokens.space8),
                  Expanded(
                    child: Text(
                      'Please verify with the customer before cancelling this order.',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.space12),
            Text(order['orderNo'], style: AppTypography.heading),
            const SizedBox(height: 2),
            Text('Customer: ${order['customer']}', style: AppTypography.bodyMuted),
            const Divider(height: 24, color: AppColors.softBorder),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Text('ITEMS', style: AppTypography.label),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Column(
                      children: items.map<Widget>((item) {
                        final itemPrice = (item['price'] as num?)?.toDouble() ?? 0;
                        final itemQty = (item['qty'] as num?)?.toInt() ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            children: [
                              Text(
                                '$itemQty×',
                                style: AppTypography.figureSmall,
                              ),
                              const SizedBox(width: AppDesignTokens.space8),
                              Expanded(
                                child: Text(item['name'], style: AppTypography.body),
                              ),
                              Text(
                                _currencyFormat.format(itemPrice * itemQty),
                                style: AppTypography.figureSmall,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignTokens.space12),
            const Divider(height: 1, color: AppColors.softBorder),
            const SizedBox(height: AppDesignTokens.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total to void:', style: AppTypography.body),
                Text(
                  _currencyFormat.format((order['total'] as num?)?.toDouble() ?? 0),
                  style: AppTypography.figure.copyWith(color: AppColors.brandRed),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AppSecondaryButton(
            text: 'Keep order',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppDestructiveButton(
            text: 'Cancel order',
            icon: Icons.delete_outline,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final cancelledCount = await _transactionRepo.cancelOrder(
        order['id'],
        reason: 'Cancelled by cashier',
        receiptNumber: order['receipt']?.toString(),
      );
      await _loadOrders();
      if (!mounted) return;
      if (cancelledCount == 0) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Order was updated during background sync. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('${order['orderNo']} has been cancelled and voided.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.brandRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar consistent with other Cashier tabs (Menu & Recent Transactions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(bottom: BorderSide(color: AppColors.softBorder, width: 1)),
            ),
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Queue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.creamBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.softBorder, width: 1),
                      ),
                      child: Text(
                        '$_inProgressCount in progress',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Filter pills consistent with cashier layout (Default: Preparing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Preparing', 'Served', 'All'].map((f) {
                    final isSelected = _statusFilter == f;
                    final count = f == 'All'
                        ? _orders.length
                        : _orders.where((o) => o['status'] == f).length;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: InkWell(
                        onTap: () => setState(() => _statusFilter = f),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.goldenYellow : AppColors.creamBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppColors.goldenYellow : AppColors.softBorder,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                f,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: AppColors.darkCharcoal,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCharcoal),
                    ),
                  )
                : _filteredOrders.isEmpty
                    ? AppEmptyState(
                        icon: Icons.soup_kitchen_outlined,
                        title: _statusFilter == 'All'
                            ? 'No orders in queue'
                            : 'No $_statusFilter orders',
                        subtitle: 'New orders will automatically appear here once punched in by the cashier.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDesignTokens.space16),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = _filteredOrders[index];
                          final status = order['status'] as String;
                          final items = order['items'] as List;
                          final isServed = status == 'Served';
                          final orderType = (order['orderType'] as String? ?? 'dine_in').toLowerCase();
                          final isTakeout = orderType == 'takeout';
                          final packagingFee = (order['packagingFee'] as num?)?.toDouble() ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppDesignTokens.space12),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppDesignTokens.space16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Order Header Row
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        order['orderNo'],
                                        style: AppTypography.heading,
                                      ),
                                      const SizedBox(width: AppDesignTokens.space8),
                                      AppStatusChip(
                                        label: status,
                                        type: isServed ? AppStatusType.success : AppStatusType.warning,
                                        icon: isServed ? Icons.check_circle_outline : Icons.soup_kitchen_outlined,
                                        isCompact: true,
                                      ),
                                      const SizedBox(width: AppDesignTokens.space8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isTakeout ? AppColors.goldenYellow : AppColors.creamBackground,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.softBorder),
                                        ),
                                        child: Text(
                                          isTakeout ? 'TAKEOUT' : 'DINE-IN',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.darkCharcoal,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _currencyFormat.format((order['total'] as num?)?.toDouble() ?? 0),
                                        style: AppTypography.figure,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppDesignTokens.space8),
                                  // Metadata Row
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        Text(order['customer'], style: AppTypography.bodyMuted),
                                        _dot(),
                                        Text(order['time'], style: AppTypography.bodyMuted),
                                        _dot(),
                                        Text(
                                          'Receipt ${order['receipt']}',
                                          style: AppTypography.bodyMuted,
                                        ),
                                        _dot(),
                                        Text(order['payment'], style: AppTypography.bodyMuted),
                                        if (order['notes'] != null &&
                                            (order['notes'] as String).isNotEmpty) ...[
                                          _dot(),
                                          const Icon(
                                            Icons.sticky_note_2_outlined,
                                            size: 14,
                                            color: AppColors.darkCharcoal,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            order['notes'],
                                            style: AppTypography.body.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 20, color: AppColors.softBorder),
                                  // Items section
                                  const Text('ITEMS', style: AppTypography.label),
                                  const SizedBox(height: AppDesignTokens.space4),
                                  ...items.map<Widget>((item) {
                                    final itemPrice = (item['price'] as num?)?.toDouble() ?? 0;
                                    final itemQuantity = (item['qty'] as num?)?.toInt() ?? 0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              '$itemQuantity×',
                                              style: AppTypography.figureSmall,
                                            ),
                                          ),
                                          const SizedBox(width: AppDesignTokens.space8),
                                          Expanded(
                                            child: Text(
                                              item['name'],
                                              style: AppTypography.body,
                                            ),
                                          ),
                                          Text(
                                            _currencyFormat.format(itemPrice * itemQuantity),
                                            style: AppTypography.figureSmall,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (packagingFee > 0)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 40),
                                          const Expanded(
                                            child: Text(
                                              'Packaging Fee (Takeout)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: AppColors.mutedBrown,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _currencyFormat.format(packagingFee),
                                            style: AppTypography.figureSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: AppDesignTokens.space8),
                                  // Footer Action Row
                                  if (isServed)
                                    Padding(
                                      padding: const EdgeInsets.only(top: AppDesignTokens.space8),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: AppColors.forest,
                                          ),
                                          const SizedBox(width: AppDesignTokens.space8),
                                          Text(
                                            'Order completed and served',
                                            style: AppTypography.body.copyWith(
                                              color: AppColors.forest,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (!isServed) ...[
                                    const Divider(height: 20, color: AppColors.softBorder),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _cancelOrder(order),
                                          icon: const Icon(Icons.cancel_outlined, size: 16),
                                          label: const Text('Cancel Order'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.brandRed,
                                            textStyle: AppTypography.buttonSmall,
                                          ),
                                        ),
                                        const Spacer(),
                                        AppPrimaryButton(
                                          text: 'Mark as Served',
                                          icon: Icons.check_circle_outline,
                                          onPressed: () => _advanceStatus(order),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '·',
        style: AppTypography.label,
      ),
    );
  }
}

