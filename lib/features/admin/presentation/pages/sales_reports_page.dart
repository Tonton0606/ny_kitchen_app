import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/services/export_service.dart';
import '../../../../../core/services/sync_service.dart';
import 'package:intl/intl.dart';

class SalesReportsPage extends StatefulWidget {
  const SalesReportsPage({super.key});

  @override
  State<SalesReportsPage> createState() => _SalesReportsPageState();
}

class _SalesReportsPageState extends State<SalesReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TransactionRepository _txRepo = TransactionRepository();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    SyncService.onSyncCompletedNotifier.addListener(_loadData);
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

  @override
  void dispose() {
    SyncService.onSyncCompletedNotifier.removeListener(_loadData);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      labelColor: AppColors.darkCharcoal,
                      unselectedLabelColor: AppColors.mutedBrown,
                      indicatorColor: AppColors.goldenYellow,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'All'),
                        Tab(text: 'Today'),
                        Tab(text: 'Weekly'),
                        Tab(text: 'Monthly'),
                        Tab(text: 'Annual'),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_isLoading) return;
                        if (_transactions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No transactions to print')),
                          );
                          return;
                        }
                        ExportService.printPDF(_transactions);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkCharcoal,
                        side: const BorderSide(color: AppColors.softBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      onSelected: (value) {
                        if (_isLoading) return;
                        if (_transactions.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No transactions to export')),
                          );
                          return;
                        }
                        if (value == 'excel') {
                          ExportService.exportToExcel(_transactions, context);
                        } else if (value == 'pdf') {
                          ExportService.exportToPDF(_transactions, context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'excel',
                          child: Text('Export as Excel (.xlsx)'),
                        ),
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Text('Export as PDF (.pdf)'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.download, size: 18, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Export', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
               controller: _tabController,
               children: [
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'All',
                   -1,
                   showDateFilter: true,
                 ),
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Today',
                   0,
                 ),
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Weekly',
                   7,
                   showDateFilter: true,
                 ),
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Monthly',
                   30,
                   showDateFilter: true,
                 ),
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Annual',
                   365,
                   showDateFilter: true,
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }
  List<Map<String, dynamic>> _getFilteredTransactions(int days) {
    final now = DateTime.now();
    return _transactions.where((tx) {
      final date = DateTime.tryParse(tx['created_at'] ?? '') ?? now;

      if (_selectedDateRange != null) {
        final end = _selectedDateRange!.end.add(const Duration(days: 1));
        if (date.isBefore(_selectedDateRange!.start) || date.isAfter(end)) return false;
      } else {
        if (days == 0) {
          if (date.year != now.year || date.month != now.month || date.day != now.day) return false;
        } else if (days > 0) {
          if (now.difference(date).inDays > days) return false;
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final receiptNo = (tx['receipt_number'] as String? ?? '').toLowerCase();
        final orderNo = (tx['order_number']?.toString() ?? '').toLowerCase();
        if (!receiptNo.contains(q) && !orderNo.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildReportTab(
    String period,
    int days,
    {bool showDateFilter = false}
  ) {
    final filteredTransactions = _getFilteredTransactions(days);
    
    double revenueVal = 0;
    int ordersVal = 0;
    
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    for (var tx in filteredTransactions) {
      if (tx['status'] == 'Voided' || tx['status'] == 'Refunded') continue;
      revenueVal += parseAmount(tx['total_amount']);
      ordersVal++;
    }
    final avgOrderVal = ordersVal == 0 ? 0.0 : revenueVal / ordersVal;

    final revenue = '₱${revenueVal.toStringAsFixed(2)}';
    final avgOrder = '₱${avgOrderVal.toStringAsFixed(2)}';
    final orders = ordersVal.toString();
    final completionRate = '100%';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1100;
        final gridCount = isMobile ? 1 : (isTablet ? 2 : 4);
        final gridAspectRatio = isMobile ? 2.5 : (isTablet ? 2.3 : 2.2);

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by receipt number...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.softBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  if (showDateFilter) ...[
                    const SizedBox(width: 12),
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
                                  surface: Colors.white,
                                  onSurface: AppColors.darkCharcoal,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range, size: 18, color: AppColors.goldenYellow),
                      label: Text(
                        _selectedDateRange != null 
                            ? '${DateFormat('MM/dd').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd').format(_selectedDateRange!.end)}'
                            : (isMobile ? 'Filter' : 'Filter Date'),
                        style: const TextStyle(color: AppColors.goldenYellow, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.softBorder),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: gridCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: gridAspectRatio,
                children: [
                  _buildSummaryCard(
                    'Total Revenue',
                    revenue,
                    Icons.attach_money,
                    AppColors.success,
                    'Gross sales for $period',
                    customIcon: const Text(
                      '₱',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        height: 1.0,
                      ),
                    ),
                  ),
                  _buildSummaryCard(
                    'Average Order',
                    avgOrder,
                    Icons.shopping_cart,
                    AppColors.info,
                    'Per transaction average',
                  ),
                  _buildSummaryCard(
                    'Total Orders',
                    orders,
                    Icons.receipt_long,
                    AppColors.tertiary,
                    'Completed transactions',
                  ),
                  _buildSummaryCard(
                    'Completion Rate',
                    completionRate,
                    Icons.check,
                    AppColors.goldenYellow,
                    'Successful rate',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.softBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transactions',
                            style: AppTypography.sectionTitle,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldenYellow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '$period Report',
                                  style: const TextStyle(
                                    color: AppColors.darkCharcoal,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_selectedDateRange != null || _searchQuery.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedDateRange = null;
                                        _searchQuery = '';
                                      });
                                    },
                                    child: const Icon(Icons.close, size: 14, color: AppColors.brandRed),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.softBorder),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth > 48 ? constraints.maxWidth - 48 : 700,
                        ),
                        child: DataTable(
                          headingRowHeight: 48,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 56,
                          horizontalMargin: 24,
                          columnSpacing: constraints.maxWidth > 900 ? 56.0 : 24.0,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Receipt No',
                                style: AppTypography.tableHeader,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Date & Time',
                                style: AppTypography.tableHeader,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Cashier',
                                style: AppTypography.tableHeader,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Items',
                                style: AppTypography.tableHeader,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Total',
                                style: AppTypography.tableHeader,
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: AppTypography.tableHeader,
                              ),
                            ),
                          ],
                          rows: filteredTransactions.map((tx) {
                            final status = tx['status'] as String? ?? 'Unknown';
                            final isSuccess = status == 'Completed' || status == 'Served';
                            final isVoided = status == 'Voided';
                            final isRefunded = status == 'Refunded';
                            Color statusColor;
                            if (isSuccess) {
                              statusColor = AppColors.success;
                            } else if (isVoided) {
                              statusColor = AppColors.brandRed;
                            } else if (isRefunded) {
                              statusColor = AppColors.tertiary;
                            } else {
                              statusColor = AppColors.mutedText;
                            }
                            
                            final parsedDate = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
                            final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(parsedDate);
                            
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    tx['receipt_number'] ?? '',
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
                                    (tx['cashier_name'] as String?)?.isNotEmpty == true
                                        ? tx['cashier_name']
                                        : (tx['cashier_username'] as String?)?.isNotEmpty == true
                                            ? tx['cashier_username']
                                            : (tx['user_id'] == 1 ? 'Admin' : 'Cashier'),
                                    style: AppTypography.tableCellSecondary,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '${tx['itemCount'] ?? 0}',
                                    style: AppTypography.tableCellSecondary,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    '\u20b1${parseAmount(tx['total_amount']).toStringAsFixed(2)}',
                                    style: AppTypography.tableCellPrimary,
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    {Widget? customIcon}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: customIcon ?? Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTypography.metricLabel,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTypography.metricValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.badgeLabel.copyWith(color: AppColors.mutedText),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Icon(
              title == 'Completion Rate' ? Icons.pie_chart_outline : Icons.show_chart,
              color: color.withValues(alpha: 0.15),
              size: 36,
            ),
          ),
        ],
      ),
    );
  }
}
