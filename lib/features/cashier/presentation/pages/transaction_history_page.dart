import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
import 'package:intl/intl.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final TransactionRepository _repository = TransactionRepository();
  final AuditRepository _auditRepo = AuditRepository();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    // Poll every 3 seconds to keep history up to date
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadTransactions();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final data = await _repository.getAllTransactions();
    // For each transaction, we might also want to know how many items it has, 
    // but we can query it or just show the total amount.
    // For now, let's query the items count for each transaction.
    List<Map<String, dynamic>> enrichedData = [];
    for (var tx in data) {
      final items = await _repository.getTransactionItems(tx['id']);
      enrichedData.add({
        ...tx,
        'itemCount': items.length,
      });
    }

    if (mounted) {
      setState(() {
        _transactions = enrichedData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "View today's past orders",
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found.',
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          final isVoided = tx['status'] == 'Voided';
                          final dateStr = tx['created_at'];
                          final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
                          final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(parsedDate);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            color: AppColors.surfaceWhite,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.15),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              horizontalTitleGap: 12,
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isVoided
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primary.withValues(alpha: 0.2),
                                child: Icon(
                                  isVoided ? Icons.block : Icons.receipt,
                                  color: isVoided
                                      ? Theme.of(context).colorScheme.onSurfaceVariant
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tx['receipt_number'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      decoration: isVoided
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  Text(
                                    '₱${(tx['total_amount'] as num).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: isVoided
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.error,
                                      decoration: isVoided
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    '$formattedDate • ${tx['itemCount']} Items • ${tx['payment_method']}',
                                    style: const TextStyle(
                                      color: AppColors.mutedText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isVoided
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.outlineVariant
                                              : Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          tx['status'] ?? '',
                                          style: TextStyle(
                                            color: isVoided
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSurfaceVariant
                                                : Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isVoided
                                  ? IconButton(
                                      icon: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                                      tooltip: 'View Receipt',
                                      onPressed: () => _showReceipt(tx),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.block, color: AppColors.brandRed),
                                          tooltip: 'Void Transaction',
                                          onPressed: () => _confirmVoid(tx),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                                          tooltip: 'View Receipt',
                                          onPressed: () => _showReceipt(tx),
                                        ),
                                      ],
                                    ),
                              onTap: () => _showReceipt(tx),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReceipt(Map<String, dynamic> tx) async {
    List<Map<String, dynamic>> items;
    try {
      items = await _repository.getTransactionItems(tx['id']);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading receipt: $e'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!mounted) return;

    final dateStr = tx['created_at'];
    final parsedDate = DateTime.tryParse(dateStr) ?? DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy  h:mm a').format(parsedDate);

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, secondaryAnimation) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SafeArea(
              child: SizedBox(
                width: MediaQuery.sizeOf(ctx).width.clamp(0.0, 420.0),
                height: double.infinity,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/branding/ny_kitchen_emblem.png',
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(Icons.receipt_long, size: 28, color: AppColors.goldenYellow),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order Receipt', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkCharcoal)),
                                Text('N.Y Kitchen', style: TextStyle(fontSize: 11, color: AppColors.mutedText)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.softBorder),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(tx['receipt_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkCharcoal)),
                                Text(formattedDate, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: AppColors.softBorder),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const SizedBox(width: 28),
                                const Text('Item', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.5)),
                                const Spacer(),
                                const Text('Amount', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.mutedText, letterSpacing: 0.5)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ...items.map((item) {
                              final qty = item['quantity'] as int;
                              final subtotal = (item['subtotal'] as num).toDouble();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkCharcoal), textAlign: TextAlign.right),
                                    ),
                                    const SizedBox(width: 4),
                                    Text('x', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(item['food_name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkCharcoal)),
                                    ),
                                    Text('₱${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.darkCharcoal)),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: AppColors.softBorder),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.darkCharcoal)),
                                Text('₱${(tx['total_amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.darkCharcoal)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (tx['amount_received'] != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Cash Received', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                                  Text('₱${(tx['amount_received'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkCharcoal)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Change', style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                                  Text('₱${(tx['change'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.brandRed)),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatusBadge(tx['status'] as String? ?? ''),
                                const SizedBox(width: 8),
                                Icon(Icons.payments_outlined, size: 14, color: AppColors.mutedText),
                                const SizedBox(width: 4),
                                Text(tx['payment_method'] ?? 'Cash', style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isVoided = status == 'Voided';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isVoided ? Colors.grey.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isVoided ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.green,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _confirmVoid(Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Void Transaction'),
          content: Text('Are you sure you want to void receipt ${tx['receipt_number']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRed, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(ctx);
                await _repository.updateTransactionStatus(tx['id'], 'Voided');
                await _auditRepo.logAction(
                  userId: 1, // System default for now
                  username: 'admin',
                  role: 'admin',
                  module: 'Transactions',
                  action: 'Void Transaction',
                  status: 'Success',
                  description: 'Voided receipt ${tx['receipt_number']}',
                );
                _loadTransactions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Receipt ${tx['receipt_number']} voided successfully.')),
                  );
                }
              },
              child: const Text('Void'),
            ),
          ],
        );
      },
    );
  }
}
