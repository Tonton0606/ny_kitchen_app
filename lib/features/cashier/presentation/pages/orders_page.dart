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
    'Taken': Color(0xFFFF9800),
    'Preparing': Color(0xFF2196F3),
    'Ready': Color(0xFF4CAF50),
    'Served': Color(0xFF9E9E9E),
  };

  static const _flow = ['Taken', 'Preparing', 'Ready', 'Served'];

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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _statusColors[nextStatus]?.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                nextStatus == 'Preparing'
                    ? Icons.restaurant
                    : nextStatus == 'Ready'
                    ? Icons.done
                    : Icons.done_all,
                color: _statusColors[nextStatus],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Advance Order',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order['orderNo'],
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Customer: ${order['customer']}',
              style: const TextStyle(color: AppColors.mutedText),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statusChip(
                  order['status'] as String,
                  _statusColors[order['status']]!,
                ),
                const Icon(Icons.arrow_forward, color: AppColors.mutedText),
                _statusChip(nextStatus, _statusColors[nextStatus]!),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₱${((order['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} total',
              style: const TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Update in database
              try {
                await _transactionRepo.updateTransactionStatus(
                  order['id'],
                  nextStatus,
                );
                await _loadOrders(); // Refresh
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('${order['orderNo']} moved to $nextStatus'),
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () async {
                          await _transactionRepo.updateTransactionStatus(
                            order['id'],
                            _flow[currentIdx],
                          );
                          await _loadOrders();
                        },
                      ),
                    ),
                  );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: _statusColors[nextStatus],
            ),
            child: Text('Mark as $nextStatus'),
          ),
        ],
      ),
    );
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
              children: ['All', 'Taken', 'Preparing', 'Ready', 'Served'].map((
                f,
              ) {
                final isSelected = _statusFilter == f;
                final count = f == 'All'
                    ? _orders.length
                    : _orders.where((o) => o['status'] == f).length;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text('$f $count'),
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
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _advanceStatus(order),
                                    icon: Icon(
                                      status == 'Taken'
                                          ? Icons.restaurant
                                          : status == 'Preparing'
                                          ? Icons.done
                                          : Icons.done_all,
                                      size: 18,
                                    ),
                                    label: Text(
                                      status == 'Taken'
                                          ? 'Prepare'
                                          : status == 'Preparing'
                                          ? 'Ready'
                                          : 'Serve',
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: statusColor,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                  ),
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
