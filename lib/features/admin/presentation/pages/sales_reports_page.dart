import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/services/export_service.dart';
import '../../../../../core/services/sync_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../shared/widgets/app_status_chip.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage> {
  final TransactionRepository _txRepo = TransactionRepository();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  // Filter States
  String _selectedPeriod = 'Today';
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCashier = 'All';

  final TextEditingController _searchController = TextEditingController();

  static const List<String> _periodOptions = [
    'Today',
    'Weekly',
    'Monthly',
    'Annual',
    'All',
  ];

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 2,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
    SyncService.onSyncCompletedNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    SyncService.onSyncCompletedNotifier.removeListener(_loadData);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await _txRepo.getAllTransactions();
      List<Map<String, dynamic>> enrichedData = [];
      for (var tx in data) {
        final items = await _txRepo.getTransactionItems(tx['id']);
        enrichedData.add({...tx, 'itemCount': items.length});
      }

      if (mounted) {
        setState(() {
          _transactions = enrichedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Sales reports load error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double _parseAmount(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  String _formatCurrency(num amount) => _currencyFormat.format(amount);

  String _getCashierName(Map<String, dynamic> tx) {
    if (tx['cashier_role']?.toString().toLowerCase() == 'admin' ||
        tx['user_id'] == 1) {
      return 'Head Cashier';
    }
    final name = tx['cashier_name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      if (name.toLowerCase().contains('admin')) {
        return 'Head Cashier';
      }
      return name.trim();
    }
    final username = tx['cashier_username'] as String?;
    if (username != null && username.trim().isNotEmpty) {
      if (username.toLowerCase().contains('admin')) {
        return 'Head Cashier';
      }
      return username.trim();
    }
    return 'Head Cashier';
  }

  List<String> get _availableCashiers {
    final cashiers = <String>{'All'};
    for (final tx in _transactions) {
      final name = _getCashierName(tx);
      if (name.isNotEmpty) {
        cashiers.add(name);
      }
    }
    return cashiers.toList();
  }

  List<String> get _availableStatuses {
    final statuses = <String>{'All', 'Completed', 'Served', 'Voided', 'Refunded'};
    for (final tx in _transactions) {
      final s = tx['status'] as String?;
      if (s != null && s.trim().isNotEmpty) {
        statuses.add(s.trim());
      }
    }
    return statuses.toList();
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    final now = DateTime.now();

    return _transactions.where((tx) {
      final date = DateTime.tryParse(tx['created_at'] ?? '') ?? now;

      // 1. Date scope (Date range picker overrides period preset)
      if (_selectedDateRange != null) {
        final start = DateTime(
          _selectedDateRange!.start.year,
          _selectedDateRange!.start.month,
          _selectedDateRange!.start.day,
        );
        final end = DateTime(
          _selectedDateRange!.end.year,
          _selectedDateRange!.end.month,
          _selectedDateRange!.end.day,
          23,
          59,
          59,
        );
        if (date.isBefore(start) || date.isAfter(end)) return false;
      } else {
        if (_selectedPeriod == 'Today') {
          if (date.year != now.year || date.month != now.month || date.day != now.day) {
            return false;
          }
        } else if (_selectedPeriod == 'Weekly') {
          if (now.difference(date).inDays > 7) return false;
        } else if (_selectedPeriod == 'Monthly') {
          if (now.difference(date).inDays > 30) return false;
        } else if (_selectedPeriod == 'Annual') {
          if (now.difference(date).inDays > 365) return false;
        }
      }

      // 2. Status filter
      if (_selectedStatus != 'All') {
        final status = (tx['status'] as String? ?? '').toLowerCase();
        if (status != _selectedStatus.toLowerCase()) return false;
      }

      // 3. Cashier filter
      if (_selectedCashier != 'All') {
        final cashier = _getCashierName(tx);
        if (cashier != _selectedCashier) return false;
      }

      // 4. Search query
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final receiptNo = (tx['receipt_number'] as String? ?? '').toLowerCase();
        final orderNo = (tx['order_number']?.toString() ?? '').toLowerCase();
        if (!receiptNo.contains(q) && !orderNo.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  bool get _hasActiveFilters {
    return _searchQuery.trim().isNotEmpty ||
        _selectedStatus != 'All' ||
        _selectedCashier != 'All' ||
        _selectedDateRange != null;
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedCashier = 'All';
      _selectedDateRange = null;
    });
  }

  String _getDateLineText() {
    final now = DateTime.now();
    if (_selectedDateRange != null) {
      final s = DateFormat('MMM d').format(_selectedDateRange!.start);
      final e = DateFormat('MMM d, yyyy').format(_selectedDateRange!.end);
      return '$s - $e'.toUpperCase();
    }
    switch (_selectedPeriod) {
      case 'Today':
        return DateFormat('EEEE, MMMM d, yyyy').format(now).toUpperCase();
      case 'Weekly':
        final start = now.subtract(const Duration(days: 7));
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(now)}'.toUpperCase();
      case 'Monthly':
        return DateFormat('MMMM yyyy').format(now).toUpperCase();
      case 'Annual':
        return 'YEAR ${now.year}'.toUpperCase();
      default:
        return 'ALL RECORDED TRANSACTIONS';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredTransactions();

    // Compute metrics honestly from state
    double revenueVal = 0.0;
    int completedCount = 0;
    int voidedCount = 0;

    for (final tx in filtered) {
      final status = (tx['status'] as String? ?? '').toLowerCase();
      final isVoidOrRefund = status == 'voided' || status == 'refunded';
      if (isVoidOrRefund) {
        voidedCount++;
      } else {
        revenueVal += _parseAmount(tx['total_amount']);
        completedCount++;
      }
    }

    final avgOrderVal = completedCount == 0 ? 0.0 : revenueVal / completedCount;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDesignTokens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Context & Action Header
                  _buildHeaderBar(context, filtered),
                  const SizedBox(height: AppDesignTokens.space24),

                  // Visual Hierarchy: Hero KPI + Supporting Metrics
                  _buildMetricsSection(
                    revenueVal: revenueVal,
                    avgOrderVal: avgOrderVal,
                    completedCount: completedCount,
                    voidedCount: voidedCount,
                  ),
                  const SizedBox(height: AppDesignTokens.space24),

                  // Transactions Card with Filter Toolbar & Table
                  _buildTransactionsCard(context, filtered),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderBar(BuildContext context, List<Map<String, dynamic>> filtered) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppDesignTokens.space12,
          runSpacing: AppDesignTokens.space12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Left: Dateline + Period Selector
            Wrap(
              spacing: AppDesignTokens.space16,
              runSpacing: AppDesignTokens.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  _getDateLineText(),
                  style: AppTypography.label,
                ),
                _buildPeriodSelector(),
              ],
            ),

            // Right: Print & Export Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    if (filtered.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No transactions to print')),
                      );
                      return;
                    }
                    ExportService.printPDF(filtered);
                  },
                  icon: const Icon(LucideIcons.printer, size: 16),
                  label: const Text('Print', style: AppTypography.buttonSmall),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkCharcoal,
                    side: const BorderSide(color: AppColors.softBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.space16,
                      vertical: AppDesignTokens.space12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    ),
                    backgroundColor: AppColors.surfaceWhite,
                  ),
                ),
                const SizedBox(width: AppDesignTokens.space8),
                PopupMenuButton<String>(
                  offset: const Offset(0, 42),
                  onSelected: (value) {
                    if (filtered.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No transactions to export')),
                      );
                      return;
                    }
                    if (value == 'excel') {
                      ExportService.exportToExcel(filtered, context);
                    } else if (value == 'pdf') {
                      ExportService.exportToPDF(filtered, context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'excel',
                      child: Text('Export as Excel (.xlsx)', style: AppTypography.buttonSmall),
                    ),
                    const PopupMenuItem(
                      value: 'pdf',
                      child: Text('Export as PDF (.pdf)', style: AppTypography.buttonSmall),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.space16,
                      vertical: AppDesignTokens.space12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldenYellow,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.download, size: 16, color: AppColors.darkCharcoal),
                        SizedBox(width: AppDesignTokens.space8),
                        Text(
                          'Export',
                          style: AppTypography.buttonSmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _periodOptions.map((period) {
          final isSelected = _selectedPeriod == period && _selectedDateRange == null;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedPeriod = period;
                _selectedDateRange = null;
              });
            },
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            child: AnimatedContainer(
              duration: AppDesignTokens.motionFast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesignTokens.space12,
                vertical: AppDesignTokens.space4 + 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.goldenYellow : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              ),
              child: Text(
                period,
                style: isSelected
                    ? AppTypography.buttonSmall.copyWith(fontWeight: FontWeight.w800)
                    : AppTypography.buttonSmall,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMetricsSection({
    required double revenueVal,
    required double avgOrderVal,
    required int completedCount,
    required int voidedCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 960;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 960;

        final heroCard = _buildHeroRevenueCard(
          revenue: _formatCurrency(revenueVal),
          completedCount: completedCount,
          avgOrder: _formatCurrency(avgOrderVal),
        );

        final avgOrderCard = _buildSecondaryMetricCard(
          label: 'AVERAGE ORDER',
          value: _formatCurrency(avgOrderVal),
          subtitle: 'Per completed transaction',
        );

        final completedCard = _buildSecondaryMetricCard(
          label: 'COMPLETED ORDERS',
          value: '$completedCount',
          subtitle: completedCount == 1 ? '1 completed order' : '$completedCount completed orders',
        );

        final voidedCard = _buildSecondaryMetricCard(
          label: 'VOIDED & REFUNDED',
          value: '$voidedCount',
          subtitle: voidedCount > 0 ? 'Requires attention' : 'No cancelled orders',
          isDestructive: voidedCount > 0,
        );

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: heroCard),
              const SizedBox(width: AppDesignTokens.space16),
              Expanded(flex: 3, child: avgOrderCard),
              const SizedBox(width: AppDesignTokens.space16),
              Expanded(flex: 3, child: completedCard),
              const SizedBox(width: AppDesignTokens.space16),
              Expanded(flex: 3, child: voidedCard),
            ],
          );
        } else if (isTablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heroCard,
              const SizedBox(height: AppDesignTokens.space12),
              Row(
                children: [
                  Expanded(child: avgOrderCard),
                  const SizedBox(width: AppDesignTokens.space12),
                  Expanded(child: completedCard),
                  const SizedBox(width: AppDesignTokens.space12),
                  Expanded(child: voidedCard),
                ],
              ),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heroCard,
              const SizedBox(height: AppDesignTokens.space12),
              avgOrderCard,
              const SizedBox(height: AppDesignTokens.space12),
              completedCard,
              const SizedBox(height: AppDesignTokens.space12),
              voidedCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildHeroRevenueCard({
    required String revenue,
    required int completedCount,
    required String avgOrder,
  }) {
    final scopeLabel = _selectedDateRange != null
        ? 'CUSTOM RANGE REVENUE'
        : '${_selectedPeriod.toUpperCase()} REVENUE';

    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                scopeLabel,
                style: AppTypography.label,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: Text(
                  _selectedDateRange != null ? 'Filtered' : _selectedPeriod,
                  style: AppTypography.label.copyWith(color: AppColors.darkCharcoal),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space12),
          Text(
            revenue,
            style: AppTypography.heroMetric,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDesignTokens.space8),
          Text(
            '${completedCount == 1 ? '1 completed order' : '$completedCount completed orders'} · $avgOrder avg',
            style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryMetricCard({
    required String label,
    required String value,
    required String subtitle,
    bool isDestructive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDesignTokens.space12),
          Text(
            value,
            style: AppTypography.figure.copyWith(
              color: isDestructive ? AppColors.brandRed : AppColors.darkCharcoal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDesignTokens.space8),
          Text(
            subtitle,
            style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsCard(
    BuildContext context,
    List<Map<String, dynamic>> filtered,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Toolbar & Filter Row
          Padding(
            padding: const EdgeInsets.all(AppDesignTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Transactions',
                          style: AppTypography.heading,
                        ),
                        const SizedBox(width: AppDesignTokens.space8),
                        Text(
                          '(${filtered.length} records)',
                          style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
                        ),
                      ],
                    ),
                    if (_hasActiveFilters)
                      TextButton.icon(
                        onPressed: _resetFilters,
                        icon: const Icon(LucideIcons.x, size: 14, color: AppColors.brandRed),
                        label: Text(
                          'Clear Filters',
                          style: AppTypography.buttonSmall.copyWith(color: AppColors.brandRed),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDesignTokens.space16),
                _buildTableFilterBar(context),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.softBorder),

          // Table Content or Empty State
          if (filtered.isEmpty)
            _buildEmptyState()
          else
            _buildDataTable(context, filtered),
        ],
      ),
    );
  }

  Widget _buildTableFilterBar(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: AppDesignTokens.space12,
          runSpacing: AppDesignTokens.space12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // 1. Search Field
            SizedBox(
              width: constraints.maxWidth < 600 ? double.infinity : 240,
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: AppTypography.body.copyWith(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search receipt or order #...',
                  hintStyle: AppTypography.bodyMuted.copyWith(fontSize: 13),
                  prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppColors.mutedSlate),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 14, color: AppColors.mutedSlate),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    borderSide: const BorderSide(color: AppColors.softBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    borderSide: const BorderSide(color: AppColors.softBorder),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  filled: true,
                  fillColor: AppColors.surfaceWhite,
                ),
              ),
            ),

            // 2. Status Filter Dropdown
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                border: Border.all(
                  color: _selectedStatus != 'All' ? AppColors.darkCharcoal : AppColors.softBorder,
                  width: _selectedStatus != 'All' ? 1.5 : 1.0,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.mutedSlate),
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (val) => setState(() => _selectedStatus = val ?? 'All'),
                  items: _availableStatuses.map((status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status == 'All' ? 'All Statuses' : status,
                        style: AppTypography.body.copyWith(fontSize: 13),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 3. Cashier Filter Dropdown
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                border: Border.all(
                  color: _selectedCashier != 'All' ? AppColors.darkCharcoal : AppColors.softBorder,
                  width: _selectedCashier != 'All' ? 1.5 : 1.0,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCashier,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.mutedSlate),
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (val) => setState(() => _selectedCashier = val ?? 'All'),
                  items: _availableCashiers.map((cashier) {
                    return DropdownMenuItem<String>(
                      value: cashier,
                      child: Text(
                        cashier == 'All' ? 'All Staff' : cashier,
                        style: AppTypography.body.copyWith(fontSize: 13),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 4. Date Range Picker Button
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _selectedDateRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.goldenYellow,
                          onPrimary: AppColors.darkCharcoal,
                          surface: AppColors.surfaceWhite,
                          onSurface: AppColors.darkCharcoal,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedDateRange = picked);
                }
              },
              icon: const Icon(LucideIcons.calendar, size: 16, color: AppColors.darkCharcoal),
              label: Text(
                _selectedDateRange != null
                    ? '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}'
                    : 'Date Range',
                style: AppTypography.buttonSmall,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _selectedDateRange != null ? AppColors.darkCharcoal : AppColors.softBorder,
                  width: _selectedDateRange != null ? 1.5 : 1.0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                ),
                backgroundColor: AppColors.surfaceWhite,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.receipt, size: 40, color: AppColors.mutedSlate),
          const SizedBox(height: AppDesignTokens.space12),
          const Text(
            'No transactions found',
            style: AppTypography.heading,
          ),
          const SizedBox(height: AppDesignTokens.space4),
          Text(
            _hasActiveFilters
                ? 'Try adjusting your search query, cashier, or status filters.'
                : 'No sales recorded for this period yet.',
            style: AppTypography.bodyMuted,
            textAlign: TextAlign.center,
          ),
          if (_hasActiveFilters) ...[
            const SizedBox(height: AppDesignTokens.space16),
            OutlinedButton(
              onPressed: _resetFilters,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.softBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                ),
              ),
              child: const Text('Reset All Filters', style: AppTypography.buttonSmall),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, List<Map<String, dynamic>> filtered) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
            ),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 54,
              horizontalMargin: 20,
              columnSpacing: 28,
              headingRowColor: WidgetStateProperty.all(AppColors.pageBackground),
              columns: const [
                DataColumn(
                  label: Text('RECEIPT NO', style: AppTypography.label),
                ),
                DataColumn(
                  label: Text('DATE & TIME', style: AppTypography.label),
                ),
                DataColumn(
                  label: Text('CASHIER', style: AppTypography.label),
                ),
                DataColumn(
                  label: Text('ITEMS', style: AppTypography.label),
                  numeric: true,
                ),
                DataColumn(
                  label: Text('STATUS', style: AppTypography.label),
                ),
                DataColumn(
                  label: Text('TOTAL', style: AppTypography.label),
                  numeric: true,
                ),
              ],
              rows: filtered.map((tx) {
                final status = (tx['status'] as String? ?? 'Completed').trim();
                final statusLower = status.toLowerCase();

                AppStatusType chipType;
                if (statusLower == 'completed' || statusLower == 'served') {
                  chipType = AppStatusType.success;
                } else if (statusLower == 'voided' || statusLower == 'refunded') {
                  chipType = AppStatusType.error;
                } else if (statusLower == 'pending') {
                  chipType = AppStatusType.warning;
                } else {
                  chipType = AppStatusType.info;
                }

                final parsedDate = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
                final formattedDate = DateFormat('MMM d, yyyy  h:mm a').format(parsedDate);
                final amount = _parseAmount(tx['total_amount']);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        tx['receipt_number'] ?? tx['order_number']?.toString() ?? '—',
                        style: AppTypography.tableCellPrimary,
                      ),
                    ),
                    DataCell(
                      Text(
                        formattedDate,
                        style: AppTypography.tableCellSecondary,
                      ),
                    ),
                    DataCell(
                      Text(
                        _getCashierName(tx),
                        style: AppTypography.tableCellSecondary,
                      ),
                    ),
                    DataCell(
                      Text(
                        '${tx['itemCount'] ?? 0}',
                        style: AppTypography.tabularFigure,
                      ),
                    ),
                    DataCell(
                      AppStatusChip(
                        label: status,
                        type: chipType,
                        isCompact: true,
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatCurrency(amount),
                        style: (statusLower == 'voided' || statusLower == 'refunded')
                            ? AppTypography.tabularPrice(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ).copyWith(
                                color: AppColors.mutedSlate,
                                decoration: TextDecoration.lineThrough,
                              )
                            : AppTypography.tabularPrice(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
