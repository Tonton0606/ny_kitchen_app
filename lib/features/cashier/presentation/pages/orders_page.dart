import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/database/repositories/transaction_repository.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_state_placeholders.dart';

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
      loadedOrders.add({
        'id': txn['id'],
        'orderNo': txn['order_number'] != null ? '#${txn['order_number']}' : txn['receipt_number'],
        'status': txn['status'],
        'total': txn['total_amount'],
        'customer': txn['cashier_name'] ?? 'User ${txn['user_id']}',
        'time': txn['created_at'],
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
    final currentIdx = _flow.indexOf(order['status']);
    if (currentIdx >= _flow.length - 1) return;
    final nextStatus = _flow[currentIdx + 1];

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
                        '₱${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
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
                                    '₱${(itemPrice * itemQty).toStringAsFixed(2)}',
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
      await _transactionRepo.updateTransactionStatus(
        order['id'],
        nextStatus,
      );
      await _loadOrders();
      if (!mounted) return;
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
                                '₱${(itemPrice * itemQty).toStringAsFixed(2)}',
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
                  '₱${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
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
      await _transactionRepo.cancelOrder(
        order['id'],
        reason: 'Cancelled by cashier',
      );
      await _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('${order['orderNo']} has been cancelled.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                await _transactionRepo.updateTransactionStatus(
                  order['id'],
                  order['status'],
                );
                await _loadOrders();
              },
            ),
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
      backgroundColor: AppColors.creamBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar adhering to UI Principles
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
                      'Kitchen Queue',
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(width: AppDesignTokens.space12),
                    AppStatusChip(
                      label: '$_inProgressCount PREPARING',
                      type: AppStatusType.warning,
                      icon: Icons.soup_kitchen_outlined,
                      isCompact: true,
                    ),
                  ],
                ),
                const Spacer(),
                // Segmented Filter Tabs (Default is 'Preparing', not 'All')
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Preparing', 'Served', 'All'].map((f) {
                    final isSelected = _statusFilter == f;
                    final count = f == 'All'
                        ? _orders.length
                        : _orders.where((o) => o['status'] == f).length;
                    return Padding(
                      padding: const EdgeInsets.only(left: AppDesignTokens.space8),
                      child: InkWell(
                        onTap: () => setState(() => _statusFilter = f),
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        child: AnimatedContainer(
                          duration: AppDesignTokens.motionFast,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.goldenYellow : AppColors.surfaceWhite,
                            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
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
                                style: AppTypography.buttonSmall.copyWith(
                                  color: AppColors.darkCharcoal,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.surfaceWhite
                                      : AppColors.creamBackground,
                                  borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                                  border: isSelected
                                      ? null
                                      : Border.all(color: AppColors.softBorder, width: 0.5),
                                ),
                                child: Text(
                                  '$count',
                                  style: AppTypography.figureCustom(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
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
                                      const Spacer(),
                                      Text(
                                        '₱${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
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
                                            '₱${(itemPrice * itemQuantity).toStringAsFixed(2)}',
                                            style: AppTypography.figureSmall,
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
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

