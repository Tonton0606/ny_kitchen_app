import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
import '../../../shared/widgets/responsive_data_table.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/ny_watermark.dart';
import '../../../shared/widgets/food_image.dart';
import '../shared/widgets/sales_chart.dart';
import 'package:intl/intl.dart';

class AdminDashboardPage extends StatefulWidget {
  final void Function(int index)? onNavigate;
  final VoidCallback? onSettingsTap;

  const AdminDashboardPage({
    super.key,
    this.onNavigate,
    this.onSettingsTap,
  });

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
            // Top Clean Header & Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard Overview',
                      style: AppTypography.pageTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedPeriod == 'Today'
                          ? 'Today \u2022 ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}'
                          : 'Viewing ${_selectedPeriod.toLowerCase()} statistics',
                      style: AppTypography.pageSubtitle,
                    ),
                  ],
                ),
                _buildCleanPeriodSelector(),
              ],
            ),
            const SizedBox(height: 20),
            // Clean Top Summary Cards for Today / Selected Period
            GridView.count(
              crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isMobile ? 3.0 : (isTablet ? 2.3 : 2.05),
              children: [
                _buildStatCard(
                  context,
                  '$_selectedPeriod\'s Revenue',
                  '₱${_periodRevenue.toStringAsFixed(2)}',
                  '+12.5% vs prev',
                  Icons.attach_money,
                  AppColors.success,
                  customIcon: const Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      height: 1.0,
                    ),
                  ),
                ),
                _buildStatCard(
                  context,
                  '$_selectedPeriod\'s Orders',
                  '$_periodOrders',
                  '+5.2% volume',
                  Icons.shopping_bag_outlined,
                  AppColors.info,
                ),
                _buildStatCard(
                  context, 
                  'Monthly Revenue',
                  '₱${_monthlyRevenue.toStringAsFixed(2)}',
                  'Month-to-date',
                  Icons.show_chart_rounded,
                  AppColors.tertiary,
                  customIcon: const Text(
                    '₱',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.tertiary,
                      height: 1.0,
                    ),
                  ),
                ),
                _buildStatCard(
                  context, 
                  'Active Cashiers',
                  '2',
                  'Active on shift',
                  Icons.badge_outlined,
                  AppColors.goldenYellow,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Two-column layout: Left data (Sales Trend + Recent Tx) moved UP, Right column has Quick Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionCard(
                        context, 
                        'Sales Trend',
                        _isLoading 
                            ? const SizedBox(height: 250, child: Center(child: CircularProgressIndicator())) 
                            : SalesChart(data: _hourlyData),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionCard(
                        context, 
                        'Recent Transactions',
                        _buildRecentTransactionsTable(context),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const SizedBox(width: 24),
                if (!isMobile)
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildQuickActionsBanner(context),
                        const SizedBox(height: 24),
                        _buildSectionCard(
                          context, 
                          'Top Selling Foods',
                          _buildTopSellingList(context),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionCard(
                          context, 
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
              _buildQuickActionsBanner(context),
              const SizedBox(height: 24),
              _buildSectionCard(context, 'Top Selling Foods', _buildTopSellingList(context)),
              const SizedBox(height: 24),
              _buildSectionCard(
                context, 
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

  Widget _buildCleanPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.softBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCleanPeriodItem('Today'),
          const SizedBox(width: 4),
          _buildCleanPeriodItem('Week'),
          const SizedBox(width: 4),
          _buildCleanPeriodItem('Month'),
        ],
      ),
    );
  }

  Widget _buildCleanPeriodItem(String label) {
    final isSelected = _selectedPeriod == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPeriod = label;
        });
        _loadDashboardData();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.darkCharcoal.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: AppColors.softBorder, width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.darkCharcoal : AppColors.mutedBrown,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, 
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    {Widget? customIcon}
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.metricLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: customIcon ?? Icon(icon, color: color, size: 18),
                ),
              ),
            ],
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: AppTypography.metricValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subtitle,
                  style: AppTypography.badgeLabel.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
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
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.sectionTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (title == 'Recent Transactions')
                TextButton(
                  onPressed: () => widget.onNavigate?.call(1),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                )
              else if (title == 'Recent Activities')
                TextButton(
                  onPressed: () => widget.onNavigate?.call(4),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
            style: AppTypography.tableCellPrimary,
          )),
          DataCell(Text(timeStr, style: AppTypography.tableCellSecondary)),
          DataCell(Text('\u20b1${(tx['total_amount'] as num).toStringAsFixed(2)}', style: AppTypography.tableCellPrimary)),
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
                    color: AppColors.goldenYellow,
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

  Widget _buildQuickActionsBanner(BuildContext context) {
    final actions = [
      _QuickActionData(
        title: 'Add Food Item',
        icon: Icons.restaurant_menu_outlined,
        onTap: () => widget.onNavigate?.call(2), // Food Management
      ),
      _QuickActionData(
        title: 'Register Staff',
        icon: Icons.person_add_outlined,
        onTap: () => widget.onNavigate?.call(3), // Account Management
      ),
      _QuickActionData(
        title: 'Sales Reports',
        icon: Icons.assessment_outlined,
        onTap: () => widget.onNavigate?.call(1), // Sales Reports
      ),
      _QuickActionData(
        title: 'Activity Logs',
        icon: Icons.history_rounded,
        onTap: () => widget.onNavigate?.call(4), // Activity Logs
      ),
      _QuickActionData(
        title: 'Backup & Sync',
        icon: Icons.cloud_sync_outlined,
        onTap: () => widget.onNavigate?.call(5), // Backup & Restore
      ),
      _QuickActionData(
        title: 'User Settings',
        icon: Icons.manage_accounts_outlined,
        onTap: () {
          if (widget.onSettingsTap != null) {
            widget.onSettingsTap!();
          } else {
            widget.onNavigate?.call(3);
          }
        },
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.goldenYellow.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get started with these Quick Actions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Or select a shortcut below to manage operations',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedBrown,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const int crossAxisCount = 2;
              const double spacing = 10.0;
              final double itemWidth = (constraints.maxWidth - spacing) / crossAxisCount;
              const double itemHeight = 72.0;
              final double childAspectRatio = (itemWidth / itemHeight).clamp(1.5, 2.6);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  return _QuickActionCard(action: actions[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionCard extends StatefulWidget {
  final _QuickActionData action;

  const _QuickActionCard({required this.action});

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.goldenYellow.withValues(alpha: 0.12)
                : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered ? AppColors.goldenYellow : AppColors.softBorder,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.darkCharcoal.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.action.icon,
                size: 22,
                color: _isHovered
                    ? AppColors.darkCharcoal
                    : AppColors.darkCharcoal.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 6),
              Text(
                widget.action.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isHovered
                      ? AppColors.darkCharcoal
                      : AppColors.darkCharcoal.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
