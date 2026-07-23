import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/database/repositories/transaction_repository.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _statusFilter = 'All';

  static const _statusColors = <String, Color>{
    'Preparing': AppColors.goldenYellow,
    'Served': AppColors.mutedText,
  };

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

    // For each transaction, get items
    List<Map<String, dynamic>> loadedOrders = [];
    for (var txn in activeTxns) {
      final items = await _transactionRepo.getTransactionItems(
        txn['id'] as int,
      );
      loadedOrders.add({
        'id': txn['id'],
        'orderNo': txn['receipt_number'],
        'status': txn['status'],
        'total': txn['total_amount'],
        'customer': 'User ${txn['user_id']}',
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
      _orders.where((o) => o['status'] != 'Served').length;

  Future<void> _advanceStatus(Map<String, dynamic> order) async {
    final currentIdx = _flow.indexOf(order['status']);
    if (currentIdx >= _flow.length - 1) return;
    final nextStatus = _flow[currentIdx + 1];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _statusColors[nextStatus]!.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  nextStatus == 'Served' ? Icons.done_all : Icons.restaurant,
                  color: _statusColors[nextStatus],
                  size: 22,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Advance Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order['orderNo'],
                    style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
                  ),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order['customer'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(order['time'], style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(order['payment'], style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        '₱${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkCharcoal),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statusChip(order['status'] as String, _statusColors[order['status']]!),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward, size: 16, color: AppColors.mutedText),
                ),
                _statusChip(nextStatus, _statusColors[nextStatus]!),
              ],
            ),
            if (order['items'] != null) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                      child: Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
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
                                  Text('$itemQty×', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppColors.darkCharcoal)),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 13, color: AppColors.darkCharcoal))),
                                  Text('₱${(itemPrice * itemQty).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkCharcoal)),
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
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              side: BorderSide(color: AppColors.softBorder),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: _statusColors[nextStatus],
              foregroundColor: Colors.black,
            ),
            child: Text('Mark as $nextStatus'),
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
            content: Text('${order['orderNo']} moved to $nextStatus'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _cancelOrder(Map<String, dynamic> order) async {
    final items = order['items'] as List;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: AppColors.brandRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cancel Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.brandRed, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please verify with the customer that this is the correct order to cancel.',
                      style: TextStyle(
                        color: AppColors.brandRed,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              order['orderNo'],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: ${order['customer']}',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
            ),
            const Divider(height: 1, color: AppColors.softBorder),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Text(
                      'Items',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.mutedText),
                    ),
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
                                '${itemQty}x ',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                              Expanded(child: Text(item['name'], style: const TextStyle(fontSize: 13))),
                              Text(
                                '₱${(itemPrice * itemQty).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
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
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.softBorder),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  '₱${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.brandRed),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel order'),
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
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Orders',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'serif',
                    letterSpacing: -0.4,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_inProgressCount in progress',
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: ['All', 'Preparing', 'Served'].map((
                f,
              ) {
                final isSelected = _statusFilter == f;
                final count = f == 'All'
                    ? _orders.length
                    : _orders.where((o) => o['status'] == f).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: f == 'All'
                        ? const Text('All')
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(f),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.black
                                        : AppColors.mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _statusFilter = f),
                    selectedColor: Theme.of(context).colorScheme.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _statusFilter == 'All'
                              ? 'No orders yet'
                              : 'No $_statusFilter orders',
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      final status = order['status'] as String;
                      final statusColor = _statusColors[status] ?? Colors.grey;
                      final items = order['items'] as List;

                      final isServed = status == 'Served';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order['orderNo'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₱${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...items.map<Widget>((item) {
                                final itemPrice =
                                    (item['price'] as num?)?.toDouble() ?? 0;
                                final itemQuantity =
                                    (item['qty'] as num?)?.toInt() ?? 0;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 3),
                                  child: Row(
                                    children: [
                                      Text(
                                        '${itemQuantity}x',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Text(
                                        '₱${(itemPrice * itemQuantity).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _meta(order['customer']),
                                    _dot(),
                                    _meta(order['time']),
                                    _dot(),
                                    _meta(order['payment']),
                                    if (order['notes'] != null &&
                                        (order['notes'] as String)
                                            .isNotEmpty) ...[
                                      _dot(),
                                      Icon(
                                        Icons.notes,
                                        size: 13,
                                        color: AppColors.goldenYellow,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        order['notes'],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.goldenYellow,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isServed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: Colors.green.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Order completed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (!isServed) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _cancelOrder(order),
                                      icon: const Icon(Icons.cancel_outlined, size: 18),
                                      label: const Text('Cancel'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.brandRed,
                                        side: const BorderSide(color: AppColors.brandRed),
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: () => _advanceStatus(order),
                                      icon: const Icon(
                                        Icons.done_all,
                                        size: 18,
                                      ),
                                      label: const Text('Serve'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: statusColor,
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                      ),
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

  Widget _meta(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
