import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/repositories/audit_repository.dart';
import '../../../../core/database/repositories/transaction_repository.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../shared/widgets/app_state_placeholders.dart';
import '../../../shared/widgets/app_status_chip.dart';

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

  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    // Poll every 3 seconds to keep history up to date
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadTransactions(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }
    try {
      final data = await _repository.getAllTransactions();
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
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((tx) {
      final rawStatus = (tx['status'] as String? ?? 'Served').trim();
      final normalizedStatus = (rawStatus.toLowerCase() == 'completed' ||
              rawStatus.toLowerCase() == 'taken' ||
              rawStatus.toLowerCase() == 'ready')
          ? 'Served'
          : rawStatus;

      // Status filter
      if (_statusFilter != 'All') {
        if (_statusFilter == 'Served') {
          if (normalizedStatus.toLowerCase() != 'served') return false;
        } else if (normalizedStatus.toLowerCase() != _statusFilter.toLowerCase()) {
          return false;
        }
      }

      // Search filter (receipt number or order number)
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final receipt = (tx['receipt_number'] as String? ?? '').toLowerCase();
        final orderNo = (tx['order_number']?.toString() ?? '').toLowerCase();
        if (!receipt.contains(q) && !orderNo.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  int _countForStatus(String status) {
    if (status == 'All') return _transactions.length;
    return _transactions.where((tx) {
      final rawStatus = (tx['status'] as String? ?? 'Served').trim();
      final normalized = (rawStatus.toLowerCase() == 'completed' ||
              rawStatus.toLowerCase() == 'taken' ||
              rawStatus.toLowerCase() == 'ready')
          ? 'Served'
          : rawStatus;
      return normalized.toLowerCase() == status.toLowerCase();
    }).length;
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = 'All';
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final hasActiveFilters = _statusFilter != 'All' || _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar consistent with other Cashier tabs (Menu & Queue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceWhite,
              border: Border(bottom: BorderSide(color: AppColors.softBorder, width: 1)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title and Record Count Pill
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Recent Transactions',
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
                                '${_transactions.length} records',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),

                        // Search Box, Status Filter Pills & Refresh Button
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search Box
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220, maxHeight: 36),
                              child: TextField(
                                controller: _searchController,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(50),
                                ],
                                onChanged: (val) => setState(() => _searchQuery = val),
                                style: const TextStyle(fontSize: 12, color: AppColors.darkCharcoal),
                                decoration: InputDecoration(
                                  hintText: 'Search order or receipt #...',
                                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.mutedSlate),
                                  prefixIcon: const Icon(LucideIcons.search, size: 14, color: AppColors.mutedSlate),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close, size: 14, color: AppColors.mutedSlate),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: AppColors.creamBackground,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: const BorderSide(color: AppColors.goldenYellow, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Status Filter Pills
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: ['All', 'Served', 'Voided'].map((f) {
                                final isSelected = _statusFilter == f;
                                final count = _countForStatus(f);

                                return Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: InkWell(
                                    onTap: () => setState(() => _statusFilter = f),
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 180),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                            const SizedBox(width: 10),

                            // Refresh Button
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 18, color: AppColors.darkCharcoal),
                              onPressed: () => _loadTransactions(),
                              tooltip: 'Refresh',
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ),

          // Main Content
          Expanded(
            child: _isLoading && _transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: AppEmptyState(
                          icon: LucideIcons.receipt,
                          title: hasActiveFilters
                              ? 'No matching transactions'
                              : 'No transactions recorded yet',
                          subtitle: hasActiveFilters
                              ? 'Try adjusting your search query or status filter.'
                              : 'Completed orders and payments will appear here in real time.',
                          actionText: hasActiveFilters ? 'Reset Filters' : null,
                          onAction: hasActiveFilters ? _resetFilters : null,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppDesignTokens.space16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                          return _buildTransactionCard(tx);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final rawStatus = (tx['status'] as String? ?? 'Served').trim();
    final isVoided = rawStatus.toLowerCase() == 'voided';
    final isRefunded = rawStatus.toLowerCase() == 'refunded';
    final isServed = rawStatus.toLowerCase() == 'served' ||
        rawStatus.toLowerCase() == 'completed' ||
        rawStatus.toLowerCase() == 'taken' ||
        rawStatus.toLowerCase() == 'ready';

    final String displayStatus;
    final AppStatusType chipType;
    if (isVoided) {
      displayStatus = 'Voided';
      chipType = AppStatusType.error;
    } else if (isRefunded) {
      displayStatus = 'Refunded';
      chipType = AppStatusType.error;
    } else if (isServed) {
      displayStatus = 'Served';
      chipType = AppStatusType.success;
    } else {
      displayStatus = rawStatus;
      chipType = AppStatusType.warning;
    }

    final dateStr = tx['created_at'];
    final parsedDate = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy  h:mm a').format(parsedDate);
    final totalAmount = (tx['total_amount'] as num?)?.toDouble() ?? 0.0;
    final itemCount = tx['itemCount'] ?? 1;
    final paymentMethod = tx['payment_method'] ?? 'Cash';
    final cashierName = (tx['cashier_name'] as String?)?.trim().isNotEmpty == true
        ? tx['cashier_name']
        : (tx['cashier_username'] as String?)?.trim().isNotEmpty == true
            ? tx['cashier_username']
            : (tx['user_id'] == 1 ? 'Admin' : 'Cashier');

    return Container(
      margin: const EdgeInsets.only(bottom: AppDesignTokens.space12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(
          color: isVoided ? AppColors.brandRed.withValues(alpha: 0.25) : AppColors.softBorder,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          onTap: () => _showReceipt(tx),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isVoided
                      ? AppColors.brandRed.withValues(alpha: 0.1)
                      : AppColors.goldenYellow.withValues(alpha: 0.25),
                  child: Icon(
                    isVoided ? Icons.block : LucideIcons.receipt,
                    color: isVoided ? AppColors.brandRed : AppColors.darkCharcoal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),

                // Order and Metadata Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            tx['order_number'] != null
                                ? 'Order #${tx['order_number']}'
                                : (tx['receipt_number'] ?? 'Order'),
                            style: AppTypography.tableCellPrimary.copyWith(
                              fontWeight: FontWeight.w800,
                              decoration: isVoided ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          if (tx['receipt_number'] != null && tx['order_number'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '(${tx['receipt_number']})',
                              style: AppTypography.tableCellSecondary.copyWith(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 2,
                        runSpacing: 2,
                        children: [
                          Text(formattedDate, style: AppTypography.tableCellSecondary),
                          _dot(),
                          Text('$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                              style: AppTypography.tableCellSecondary),
                          _dot(),
                          Text('$paymentMethod', style: AppTypography.tableCellSecondary),
                          _dot(),
                          Text('$cashierName', style: AppTypography.tableCellSecondary),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and Status
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₱${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isVoided ? AppColors.mutedBrown : AppColors.darkCharcoal,
                          decoration: isVoided ? TextDecoration.lineThrough : null,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 4),
                      AppStatusChip(
                        label: displayStatus,
                        type: chipType,
                        isCompact: true,
                      ),
                    ],
                  ),
                ),

                // Actions
                if (!isVoided)
                  IconButton(
                    icon: const Icon(Icons.block, size: 18, color: AppColors.brandRed),
                    tooltip: 'Void Transaction',
                    onPressed: () => _confirmVoid(tx),
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20, color: AppColors.mutedSlate),
                  tooltip: 'View Receipt',
                  onPressed: () => _showReceipt(tx),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(color: AppColors.mutedSlate, fontWeight: FontWeight.bold),
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
        SnackBar(
          content: Text('Error loading receipt: $e'),
          backgroundColor: AppColors.brandRed,
        ),
      );
      return;
    }
    if (!mounted) return;

    final dateStr = tx['created_at'];
    final parsedDate = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy  h:mm a').format(parsedDate);
    final rawStatus = (tx['status'] as String? ?? 'Served').trim();
    final isVoided = rawStatus.toLowerCase() == 'voided';

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
                    // Receipt Panel Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/branding/ny_kitchen_emblem.png',
                            height: 28,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.receipt_long,
                              size: 28,
                              color: AppColors.goldenYellow,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Receipt',
                                  style: AppTypography.heading,
                                ),
                                Text(
                                  'N.Y Kitchen POS',
                                  style: AppTypography.bodyMuted,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 20, color: AppColors.darkCharcoal),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.softBorder),

                    // Receipt Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tx['receipt_number'] ?? '',
                                  style: AppTypography.tableCellPrimary.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(formattedDate, style: AppTypography.tableCellSecondary),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Cashier', style: AppTypography.tableCellSecondary),
                                Text(
                                  (tx['cashier_name'] as String?)?.isNotEmpty == true
                                      ? tx['cashier_name']
                                      : (tx['cashier_username'] as String?)?.isNotEmpty == true
                                          ? tx['cashier_username']
                                          : (tx['user_id'] == 1 ? 'Admin' : 'Cashier'),
                                  style: AppTypography.tableCellPrimary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1, color: AppColors.softBorder),
                            const SizedBox(height: 12),

                            // Items Header
                            const Row(
                              children: [
                                SizedBox(width: 28),
                                Text('Item', style: AppTypography.label),
                                Spacer(),
                                Text('Amount', style: AppTypography.label),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Items List
                            ...items.map((item) {
                              final qty = item['quantity'] as int;
                              final subtotal = (item['subtotal'] as num).toDouble();
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '$qty',
                                        style: AppTypography.tableCellPrimary.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('×', style: TextStyle(color: AppColors.mutedSlate)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item['food_name'],
                                        style: AppTypography.tableCellPrimary,
                                      ),
                                    ),
                                    Text(
                                      '₱${subtotal.toStringAsFixed(2)}',
                                      style: AppTypography.tableCellPrimary.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: AppColors.softBorder),
                            const SizedBox(height: 12),

                            // Total Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: AppTypography.heading),
                                Text(
                                  '₱${((tx['total_amount'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkCharcoal,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Cash Received / Change
                            if (tx['amount_received'] != null) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Amount Received',
                                      style: AppTypography.tableCellSecondary),
                                  Text(
                                    '₱${((tx['amount_received'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                    style: AppTypography.tableCellPrimary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Change', style: AppTypography.tableCellSecondary),
                                  Text(
                                    '₱${((tx['change'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.forest,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Status Chip and Method
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppStatusChip(
                                  label: isVoided ? 'VOIDED' : 'SERVED',
                                  type: isVoided ? AppStatusType.error : AppStatusType.success,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.payments_outlined,
                                    size: 14, color: AppColors.mutedSlate),
                                const SizedBox(width: 4),
                                Text(
                                  tx['payment_method'] ?? 'Cash',
                                  style: AppTypography.tableCellSecondary,
                                ),
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

  void _confirmVoid(Map<String, dynamic> tx) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.brandRed, size: 22),
              SizedBox(width: 8),
              Text('Void Transaction', style: AppTypography.heading),
            ],
          ),
          content: Text(
            'Are you sure you want to void receipt ${tx['receipt_number']}? This action will mark the transaction as cancelled and cannot be undone.',
            style: AppTypography.body,
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: AppTypography.buttonSmall),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await _repository.updateTransactionStatus(tx['id'], 'Voided');
                await _auditRepo.logAction(
                  userId: SessionManager().userId ?? 1,
                  username: SessionManager().fullName ?? 'unknown',
                  role: SessionManager().role ?? 'cashier',
                  module: 'Transactions',
                  action: 'Void Transaction',
                  status: 'Success',
                  description: 'Voided receipt ${tx['receipt_number']}',
                );
                _loadTransactions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Receipt ${tx['receipt_number']} voided successfully.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Void Transaction'),
            ),
          ],
        );
      },
    );
  }
}
