import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
import '../../../shared/widgets/responsive_data_table.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/ny_watermark.dart';
import '../../../shared/widgets/food_image.dart';
import '../shared/widgets/sales_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final TransactionRepository _txRepo = TransactionRepository();
  final AuditRepository _auditRepo = AuditRepository();
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _topSellingFoods = [];
  List<Map<String, dynamic>> _recentLogs = [];
  
  String _selectedPeriod = 'Today'; // 'Today', 'Week', 'Month'
  double _periodRevenue = 0;
  int _periodOrders = 0;
  double _monthlyRevenue = 0;
  List<Map<String, dynamic>> _hourlyData = [];

  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _parseAmount(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  Future<void> _loadDashboardData() async {
    final transactions = await _txRepo.getAllTransactions();
    final now = DateTime.now();

    double pRev = 0;
    int pOrders = 0;
    double mRev = 0;

    // Process hourly data for today
    Map<int, double> hourlyRev = {
      8: 0, 9: 0, 10: 0, 11: 0, 12: 0, 13: 0, 14: 0, 15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0
    };

    for (var tx in transactions) {
      if (tx['status'] == 'Voided' || tx['status'] == 'Refunded') continue;

      final dateStr = tx['created_at'];
      final date = DateTime.tryParse(dateStr) ?? DateTime.now();
      final amount = _parseAmount(tx['total_amount']);

      if (date.year == now.year && date.month == now.month) {
        mRev += amount;
      }
      
      bool isInPeriod = false;
      if (_selectedPeriod == 'Today') {
        if (date.year == now.year && date.month == now.month && date.day == now.day) isInPeriod = true;
      } else if (_selectedPeriod == 'Week') {
        if (now.difference(date).inDays <= 7) isInPeriod = true;
      } else if (_selectedPeriod == 'Month') {
        if (date.year == now.year && date.month == now.month) isInPeriod = true;
      }

      if (isInPeriod) {
        pRev += amount;
        pOrders++;
      }

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        if (hourlyRev.containsKey(date.hour)) {
          hourlyRev[date.hour] = hourlyRev[date.hour]! + amount;
        }
      }
    }

    final chartData = hourlyRev.entries.map((e) {
      final hourStr = '${e.key > 12 ? e.key - 12 : e.key}:00 ${e.key >= 12 ? 'PM' : 'AM'}';
      return {'hour': hourStr, 'amount': e.value};
    }).toList();

    final topFoods = await _txRepo.getTopSellingFoods(limit: 5);
    final logs = await _auditRepo.getLogs();

    if (mounted) {
      setState(() {
        _recentTransactions = transactions.take(5).toList();
        _periodRevenue = pRev;
        _periodOrders = pOrders;
        _monthlyRevenue = mRev;
        _hourlyData = chartData;
        _topSellingFoods = topFoods;
        _recentLogs = logs.take(4).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      body: Stack(
        children: [
          const NyWatermark(),
          SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal),
                    ),
                    const SizedBox(height: 8),
                     const Text(
                      'Overview of today\'s business performance',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildPeriodChip(context, 'Today', _selectedPeriod == 'Today'),
                    const SizedBox(width: 8),
                    _buildPeriodChip(context, 'Week', _selectedPeriod == 'Week'),
                    const SizedBox(width: 8),
                    _buildPeriodChip(context, 'Month', _selectedPeriod == 'Month'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            GridView.count(
              crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isMobile ? 3.5 : (isTablet ? 2.5 : 2.2),
              children: [
                _buildStatCard(
                  context,
                  '$_selectedPeriod\'s Revenue',
                  '₱${_periodRevenue.toStringAsFixed(2)}',
                  '+12.5%',
                  Icons.attach_money,
                  AppColors.success,
                  customIcon: const Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                      height: 1.0,
                    ),
                  ),
                ),
                _buildStatCard(
                  context,
                  '$_selectedPeriod\'s Orders',
                  '$_periodOrders',
                  '+5.2%',
                  Icons.shopping_bag_outlined,
                  AppColors.info,
                ),
                _buildStatCard(context, 
                  'Monthly Revenue',
                  '₱${_monthlyRevenue.toStringAsFixed(2)}',
                  'Live data',
                  Icons.show_chart,
                  AppColors.tertiary,
                  customIcon: const Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.tertiary,
                      height: 1.0,
                    ),
                  ),
                ),
                _buildStatCard(context, 
                  'Active Cashiers',
                  '2', // We could fetch from UserRepository
                  'Currently on shift',
                  Icons.people,
                  AppColors.goldenYellow,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionCard(context, 
                        'Sales Trend',
                        _isLoading ? const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())) : SalesChart(data: _hourlyData),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(context, 
                        'Recent Transactions',
                        _buildRecentTransactionsTable(context),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const SizedBox(width: 24),
                if (!isMobile)
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        _buildSectionCard(context, 
                          'Top Selling Foods',
                          _buildTopSellingList(context),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionCard(context, 
                          'Recent Activities',
                          _buildRecentActivitiesList(context),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (isMobile) ...[
              const SizedBox(height: 24),
              _buildSectionCard(context, 'Top Selling Foods', _buildTopSellingList(context)),
              const SizedBox(height: 24),
              _buildSectionCard(context, 
                'Recent Activities',
                _buildRecentActivitiesList(context),
              ),
            ],
          ],
        ),
      ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
        _loadDashboardData();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldenYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.goldenYellow : AppColors.softBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, 
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    {Widget? customIcon}
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
            child: customIcon ?? Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    value,
                    key: ValueKey<String>(value),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
              if (title == 'Recent Transactions')
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }


  Widget _buildRecentTransactionsTable(BuildContext context) {
    return ResponsiveDataTable(
      columns: const ['Order/Receipt', 'Time', 'Amount', 'Status'],
      data: _recentTransactions,
      buildRow: (tx) {
        final status = tx['status'] as String? ?? 'Unknown';
        final isSuccess = status == 'Completed' || status == 'Served';
        final isVoided = status == 'Voided';
        final isRefunded = status == 'Refunded';
        
        Color badgeColor;
        if (isSuccess) {
          badgeColor = AppColors.success;
        } else if (isVoided) {
          badgeColor = AppColors.brandRed;
        } else if (isRefunded) {
          badgeColor = AppColors.tertiary;
        } else {
          badgeColor = AppColors.mutedText; // Preparing
        }

        final parsedDate = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        final timeStr = DateFormat('h:mm a').format(parsedDate);

        return DataRow(cells: [
          DataCell(Text(
            tx['order_number'] != null ? '#${tx['order_number']} (${tx['receipt_number']})' : (tx['receipt_number'] ?? ''),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          )),
          DataCell(Text(timeStr, style: const TextStyle(fontSize: 13))),
          DataCell(Text('\u20b1${(tx['total_amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(StatusBadge(text: status, color: badgeColor)),
        ]);
      },
      buildCard: (tx) {
        return const SizedBox.shrink(); // Not used for this phase
      },
    );
  }

  Widget _buildTopSellingList(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_topSellingFoods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('No sales data yet.', style: TextStyle(color: AppColors.mutedText))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _topSellingFoods.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.softBorder),
      itemBuilder: (context, index) {
        final item = _topSellingFoods[index];
        final imagePath = item['image_path'] as String? ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              if (imagePath.isNotEmpty)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FoodImage(food: item, height: 44),
                  ),
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['sold']} sold',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\u20b1${_parseAmount(item['revenue']).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitiesList(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_recentLogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('No recent activities.', style: TextStyle(color: AppColors.mutedText))),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentLogs.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.softBorder),
      itemBuilder: (context, index) {
        final log = _recentLogs[index];
        final isSuccess = log['status'] == 'Success';
        
        final dateStr = log['created_at'] ?? '';
        String formattedDate = '';
        if (dateStr.isNotEmpty) {
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            formattedDate = '${parsedDate.month}/${parsedDate.day} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
          }
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  size: 20,
                  color: isSuccess ? AppColors.success : AppColors.brandRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['action'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${log['username'] ?? 'System'} \u2022 $formattedDate',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedText,
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
}
