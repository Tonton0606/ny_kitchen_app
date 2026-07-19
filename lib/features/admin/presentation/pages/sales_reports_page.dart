import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/services/export_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
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
  }

  @override
  void dispose() {
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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Reports',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'View, filter, and export sales data',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (!_isLoading && _transactions.isNotEmpty) {
                          ExportService.printPDF(_transactions);
                        }
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!_isLoading && _transactions.isNotEmpty) {
                          ExportService.exportToCSV(_transactions, context);
                        }
                      },
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.goldenYellow,
            unselectedLabelColor: AppColors.mutedText,
            indicatorColor: AppColors.goldenYellow,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(text: 'Today'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
              Tab(text: 'Annual'),
            ],
          ),
          Expanded(
            child: TabBarView(
               controller: _tabController,
               children: [
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Today',
                   _calculateRevenueForDays(0),
                   _calculateAvgForDays(0),
                   _calculateOrdersForDays(0),
                   '100%',
                 ),
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Weekly',
                   _calculateRevenueForDays(7),
                   _calculateAvgForDays(7),
                   _calculateOrdersForDays(7),
                   '100%',
                 ),
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Monthly',
                   _calculateRevenueForDays(30),
                   _calculateAvgForDays(30),
                   _calculateOrdersForDays(30),
                   '100%',
                 ),
                 if (_isLoading) const Center(child: CircularProgressIndicator()) else _buildReportTab(
                   'Annual',
                   _calculateRevenueForDays(365),
                   _calculateAvgForDays(365),
                   _calculateOrdersForDays(365),
                   '100%',
                 ),
               ],
             ),
          ),
        ],
      ),
    );
  }

  String _calculateRevenueForDays(int days) {
    final now = DateTime.now();
    double total = 0;
    for (var tx in _transactions) {
      if (tx['status'] == 'Voided' || tx['status'] == 'Refunded') continue;
      final date = DateTime.tryParse(tx['created_at'] ?? '') ?? now;
      if (days == 0) {
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          total += (tx['total_amount'] as num).toDouble();
        }
      } else {
        if (now.difference(date).inDays <= days) {
          total += (tx['total_amount'] as num).toDouble();
        }
      }
    }
    return '₱${total.toStringAsFixed(2)}';
  }

  String _calculateAvgForDays(int days) {
    final now = DateTime.now();
    double total = 0;
    int count = 0;
    for (var tx in _transactions) {
      if (tx['status'] == 'Voided' || tx['status'] == 'Refunded') continue;
      final date = DateTime.tryParse(tx['created_at'] ?? '') ?? now;
      if (days == 0) {
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          total += (tx['total_amount'] as num).toDouble();
          count++;
        }
      } else {
        if (now.difference(date).inDays <= days) {
          total += (tx['total_amount'] as num).toDouble();
          count++;
        }
      }
    }
    if (count == 0) return '₱0.00';
    return '₱${(total / count).toStringAsFixed(2)}';
  }

  String _calculateOrdersForDays(int days) {
    final now = DateTime.now();
    int count = 0;
    for (var tx in _transactions) {
      if (tx['status'] == 'Voided' || tx['status'] == 'Refunded') continue;
      final date = DateTime.tryParse(tx['created_at'] ?? '') ?? now;
      if (days == 0) {
        if (date.year == now.year && date.month == now.month && date.day == now.day) {
          count++;
        }
      } else {
        if (now.difference(date).inDays <= days) {
          count++;
        }
      }
    }
    return count.toString();
  }

  Widget _buildReportTab(
    String period,
    String revenue,
    String avgOrder,
    String orders,
    String completionRate,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by receipt number...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.date_range, size: 18),
                label: const Text('Filter Date'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            children: [
              _buildSummaryCard(
                'Total Revenue',
                revenue,
                Icons.attach_money,
                AppColors.success,
                'Gross sales for $period',
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
                Icons.check_circle,
                AppColors.goldenYellow,
                'Successful rate',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$period Report',
                          style: const TextStyle(
                            color: AppColors.goldenYellow,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.softBorder),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 44,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 52,
                    columnSpacing: 28,
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Receipt No',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Date & Time',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Cashier',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Items',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    rows: _transactions.map((tx) {
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              'Admin',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              '${tx['itemCount'] ?? 0}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              tx['payment_method'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          DataCell(
                            Text(
                              '\u20b1${(tx['total_amount'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkCharcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
