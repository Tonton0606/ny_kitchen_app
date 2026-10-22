import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
import '../../../shared/widgets/responsive_data_table.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/food_image.dart';
import '../../../cashier/presentation/pages/cashier_shell.dart';
import '../shared/widgets/sales_chart.dart';

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

  // Real computed delta statistics (no fake stats)
  String? _revenueDeltaText;
  bool _revenueDeltaPositive = true;
  String? _ordersDeltaText;
  bool _ordersDeltaPositive = true;
  int _activeCashiersCount = 0;
  String _cashiersSubtitle = 'No active shift';

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
    final yesterday = now.subtract(const Duration(days: 1));

    double pRev = 0;
    int pOrders = 0;
    double mRev = 0;
    double yesterdayRev = 0;
    int yesterdayOrders = 0;
    final Set<String> todayCashiers = {};

    // Process hourly data for today
    final Map<int, double> hourlyRev = {
      8: 0, 9: 0, 10: 0, 11: 0, 12: 0, 13: 0, 14: 0, 15: 0, 16: 0, 17: 0, 18: 0, 19: 0, 20: 0
    };

    for (var tx in transactions) {
      if (tx['status'] == 'Voided' || tx['status'] == 'Refunded') continue;

      final dateStr = tx['created_at'];
      final date = DateTime.tryParse(dateStr ?? '') ?? DateTime.now();
      final amount = _parseAmount(tx['total_amount']);

      // Month-to-date revenue
      if (date.year == now.year && date.month == now.month) {
        mRev += amount;
      }

      // Today's active cashiers (distinct real staff with processed orders)
      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        final cashier = (tx['cashier_name'] as String?)?.trim();
        if (cashier != null && cashier.isNotEmpty) {
          todayCashiers.add(cashier);
        }
      }

      // Yesterday's metrics for real delta computation
      if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        yesterdayRev += amount;
        yesterdayOrders++;
      }

      // Period filtering
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

      // Hourly aggregation for today's chart
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

    // Compute real deltas only when yesterday data exists
    String? revDelta;
    bool revPositive = true;
    String? ordDelta;
    bool ordPositive = true;

    if (_selectedPeriod == 'Today') {
      if (yesterdayRev > 0) {
        final diff = ((pRev - yesterdayRev) / yesterdayRev) * 100;
        revPositive = diff >= 0;
        revDelta = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}% vs yesterday';
      } else {
        revDelta = 'No previous data';
      }

      if (yesterdayOrders > 0) {
        final diff = ((pOrders - yesterdayOrders) / yesterdayOrders) * 100;
        ordPositive = diff >= 0;
        ordDelta = '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)}% vs yesterday';
      } else {
        ordDelta = 'No previous data';
      }
    } else {
      revDelta = 'No previous data';
      ordDelta = 'No previous data';
    }

    final cashierCount = todayCashiers.length;
    final cashierSub = cashierCount > 0
        ? '$cashierCount on duty today'
        : 'No cashiers active';

    final topFoods = await _txRepo.getTopSellingFoods(limit: 5);
    final logs = await _auditRepo.getLogs();

    if (mounted) {
      setState(() {
        _recentTransactions = transactions.take(5).toList();
        _periodRevenue = pRev;
        _periodOrders = pOrders;
        _monthlyRevenue = mRev;
        _hourlyData = chartData;
        _revenueDeltaText = revDelta;
        _revenueDeltaPositive = revPositive;
        _ordersDeltaText = ordDelta;
        _ordersDeltaPositive = ordPositive;
        _activeCashiersCount = cashierCount;
        _cashiersSubtitle = cashierSub;
        _topSellingFoods = topFoods;
        _recentLogs = logs.take(4).toList();
        _isLoading = false;
      });
    }
  }

  void _openPos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CashierShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Row
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
                    const SizedBox(height: AppDesignTokens.space4),
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
            const SizedBox(height: AppDesignTokens.space24),

            // Hierarchical KPI Cards
            _buildKpiMetricsSection(context),
            const SizedBox(height: AppDesignTokens.space24),

            // Main Content Layout
            if (isMobile) ...[
              _buildSectionCard(
                context,
                'Sales Trend',
                _isLoading
                    ? const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()))
                    : SalesChart(data: _hourlyData, onOpenPos: _openPos),
              ),
              const SizedBox(height: AppDesignTokens.space24),
              _buildSectionCard(
                context,
                'Recent Transactions',
                _buildRecentTransactionsTable(context),
              ),
              const SizedBox(height: AppDesignTokens.space24),
              _buildQuickActionsCard(context),
              const SizedBox(height: AppDesignTokens.space24),
              _buildSectionCard(
                context,
                'Top Selling Foods',
                _buildTopSellingList(context),
              ),
              const SizedBox(height: AppDesignTokens.space24),
              _buildSectionCard(
                context,
                'Recent Activities',
                _buildRecentActivitiesList(context),
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Analytics & Transactions
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
                              : SalesChart(data: _hourlyData, onOpenPos: _openPos),
                        ),
                        const SizedBox(height: AppDesignTokens.space24),
                        _buildSectionCard(
                          context,
                          'Recent Transactions',
                          _buildRecentTransactionsTable(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.space24),

                  // Right Column: Operational Shortcuts & Feeds
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildQuickActionsCard(context),
                        const SizedBox(height: AppDesignTokens.space24),
                        _buildSectionCard(
                          context,
                          'Top Selling Foods',
                          _buildTopSellingList(context),
                        ),
                        const SizedBox(height: AppDesignTokens.space24),
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCleanPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(AppDesignTokens.space4),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPeriodTab('Today'),
          const SizedBox(width: AppDesignTokens.space4),
          _buildPeriodTab('Week'),
          const SizedBox(width: AppDesignTokens.space4),
          _buildPeriodTab('Month'),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label) {
    final isSelected = _selectedPeriod == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = label);
        _loadDashboardData();
      },
      borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
      child: AnimatedContainer(
        duration: AppDesignTokens.motionFast,
        padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space12, vertical: AppDesignTokens.space4 + 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldenYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.darkCharcoal,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiMetricsSection(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 680) {
          // Mobile stack: Hero card first, then secondary cards
          return Column(
            children: [
              _buildHeroRevenueCard(),
              const SizedBox(height: AppDesignTokens.space12),
              _buildSecondaryCard(
                label: '$_selectedPeriod\'S ORDERS',
                value: '$_periodOrders',
                deltaText: _ordersDeltaText,
                isDeltaPositive: _ordersDeltaPositive,
              ),
              const SizedBox(height: AppDesignTokens.space12),
              _buildSecondaryCard(
                label: 'MONTHLY REVENUE',
                value: '₱${_monthlyRevenue.toStringAsFixed(2)}',
                subtitle: 'Month-to-date',
              ),
              const SizedBox(height: AppDesignTokens.space12),
              _buildSecondaryCard(
                label: 'CASHIERS ON SHIFT',
                value: '$_activeCashiersCount',
                subtitle: _cashiersSubtitle,
              ),
            ],
          );
        } else if (constraints.maxWidth < 1100) {
          // Tablet layout: Hero spans full width, 3 secondary cards below
          return Column(
            children: [
              _buildHeroRevenueCard(),
              const SizedBox(height: AppDesignTokens.space12),
              Row(
                children: [
                  Expanded(
                    child: _buildSecondaryCard(
                      label: '$_selectedPeriod\'S ORDERS',
                      value: '$_periodOrders',
                      deltaText: _ordersDeltaText,
                      isDeltaPositive: _ordersDeltaPositive,
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.space12),
                  Expanded(
                    child: _buildSecondaryCard(
                      label: 'MONTHLY REVENUE',
                      value: '₱${_monthlyRevenue.toStringAsFixed(2)}',
                      subtitle: 'Month-to-date',
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.space12),
                  Expanded(
                    child: _buildSecondaryCard(
                      label: 'CASHIERS ON SHIFT',
                      value: '$_activeCashiersCount',
                      subtitle: _cashiersSubtitle,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Desktop: Revenue as dominant anchor (flex: 3), 3 secondary cards (flex: 2 each)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildHeroRevenueCard(),
              ),
              const SizedBox(width: AppDesignTokens.space12),
              Expanded(
                flex: 2,
                child: _buildSecondaryCard(
                  label: '$_selectedPeriod\'S ORDERS',
                  value: '$_periodOrders',
                  deltaText: _ordersDeltaText,
                  isDeltaPositive: _ordersDeltaPositive,
                ),
              ),
              const SizedBox(width: AppDesignTokens.space12),
              Expanded(
                flex: 2,
                child: _buildSecondaryCard(
                  label: 'MONTHLY REVENUE',
                  value: '₱${_monthlyRevenue.toStringAsFixed(2)}',
                  subtitle: 'Month-to-date',
                ),
              ),
              const SizedBox(width: AppDesignTokens.space12),
              Expanded(
                flex: 2,
                child: _buildSecondaryCard(
                  label: 'CASHIERS ON SHIFT',
                  value: '$_activeCashiersCount',
                  subtitle: _cashiersSubtitle,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  /// Dominant Hero KPI Card for Revenue (first, larger typography, prominent anchor)
  Widget _buildHeroRevenueCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space24,
        vertical: AppDesignTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_selectedPeriod\'S REVENUE'.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.mutedBrown,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space8),
          AnimatedSwitcher(
            duration: AppDesignTokens.motionMedium,
            child: Text(
              '₱${_periodRevenue.toStringAsFixed(2)}',
              key: ValueKey<double>(_periodRevenue),
              style: AppTypography.kpiHeroValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space8),
          _buildDeltaOrSubtitle(
            deltaText: _revenueDeltaText,
            isDeltaPositive: _revenueDeltaPositive,
          ),
        ],
      ),
    );
  }

  /// Secondary, compact KPI card for supporting metrics
  Widget _buildSecondaryCard({
    required String label,
    required String value,
    String? deltaText,
    bool isDeltaPositive = true,
    String? subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space16,
        vertical: AppDesignTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.mutedBrown,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDesignTokens.space8),
          AnimatedSwitcher(
            duration: AppDesignTokens.motionMedium,
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: AppTypography.metricValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space8),
          _buildDeltaOrSubtitle(
            deltaText: deltaText,
            isDeltaPositive: isDeltaPositive,
            fallbackSubtitle: subtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaOrSubtitle({
    String? deltaText,
    bool isDeltaPositive = true,
    String? fallbackSubtitle,
  }) {
    if (deltaText != null) {
      if (deltaText == 'No previous data') {
        return const Text(
          'No previous data',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedBrown,
          ),
        );
      }
      final color = isDeltaPositive ? AppColors.forest : AppColors.brandRed;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDeltaPositive ? LucideIcons.trending_up : LucideIcons.trending_down,
            size: 13,
            color: color,
          ),
          const SizedBox(width: AppDesignTokens.space4),
          Text(
            deltaText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      );
    }
    return Text(
      fallbackSubtitle ?? '',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedBrown,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder, width: 1),
      ),
      padding: const EdgeInsets.all(AppDesignTokens.space24),
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
                    padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                )
              else if (title == 'Recent Activities')
                TextButton(
                  onPressed: () => widget.onNavigate?.call(4),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space16),
          content,
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsTable(BuildContext context) {
    if (_recentTransactions.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.receipt, size: 36, color: AppColors.mutedBrown),
            const SizedBox(height: AppDesignTokens.space8),
            const Text(
              'No recent transactions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            const Text(
              'Completed orders will appear here automatically.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedBrown,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space12),
            FilledButton.icon(
              onPressed: _openPos,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.goldenYellow,
                foregroundColor: AppColors.darkCharcoal,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesignTokens.space16,
                  vertical: AppDesignTokens.space8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                ),
              ),
              icon: const Icon(LucideIcons.shopping_bag, size: 15),
              label: const Text(
                'Open POS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return ResponsiveDataTable(
      columns: const ['Order / Receipt', 'Time', 'Amount', 'Status'],
      data: _recentTransactions,
      buildRow: (tx) {
        final status = tx['status'] as String? ?? 'Unknown';
        final isSuccess = status == 'Completed' || status == 'Served';
        final isVoided = status == 'Voided';
        final isRefunded = status == 'Refunded';

        Color badgeColor;
        if (isSuccess) {
          badgeColor = AppColors.forest;
        } else if (isVoided) {
          badgeColor = AppColors.brandRed;
        } else if (isRefunded) {
          badgeColor = AppColors.goldInk;
        } else {
          badgeColor = AppColors.mutedBrown;
        }

        final parsedDate = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        final timeStr = DateFormat('h:mm a').format(parsedDate);

        return DataRow(cells: [
          DataCell(Text(
            tx['order_number'] != null ? '#${tx['order_number']} (${tx['receipt_number']})' : (tx['receipt_number'] ?? ''),
            style: AppTypography.tableCellPrimary,
          )),
          DataCell(Text(timeStr, style: AppTypography.tableCellSecondary)),
          DataCell(Text('₱${(tx['total_amount'] as num).toStringAsFixed(2)}', style: AppTypography.tableCellPrimary)),
          DataCell(StatusBadge(text: status, color: badgeColor)),
        ]);
      },
      buildCard: (tx) => const SizedBox.shrink(),
    );
  }

  Widget _buildTopSellingList(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_topSellingFoods.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDesignTokens.space24),
        child: Center(
          child: Text(
            'No sales data recorded yet.',
            style: TextStyle(color: AppColors.mutedBrown, fontSize: 13),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.space8),
          child: Row(
            children: [
              if (imagePath.isNotEmpty)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                    child: FoodImage(food: item, height: 40),
                  ),
                )
              else
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow,
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: AppDesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Unknown Item',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['sold']} sold',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedBrown,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${_parseAmount(item['revenue']).toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.darkCharcoal,
                  fontFeatures: [FontFeature.tabularFigures()],
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
        padding: EdgeInsets.symmetric(vertical: AppDesignTokens.space24),
        child: Center(
          child: Text(
            'No recent activities recorded.',
            style: TextStyle(color: AppColors.mutedBrown, fontSize: 13),
          ),
        ),
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
          padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.space8),
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                size: 16,
                color: isSuccess ? AppColors.forest : AppColors.brandRed,
              ),
              const SizedBox(width: AppDesignTokens.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['action'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${log['username'] ?? 'System'} \u2022 $formattedDate',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedBrown,
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

  /// Compact Quick Actions Card (replaces generic tutorial lightbulb card)
  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = [
      _QuickActionItem(
        title: 'Add Food Item',
        icon: LucideIcons.utensils,
        onTap: () => widget.onNavigate?.call(2), // Food Management
      ),
      _QuickActionItem(
        title: 'Register Staff',
        icon: LucideIcons.user_plus,
        onTap: () => widget.onNavigate?.call(3), // Account Management
      ),
      _QuickActionItem(
        title: 'Sales Reports',
        icon: LucideIcons.trending_up,
        onTap: () => widget.onNavigate?.call(1), // Sales Reports
      ),
      _QuickActionItem(
        title: 'Activity Logs',
        icon: LucideIcons.clipboard_list,
        onTap: () => widget.onNavigate?.call(4), // Activity Logs
      ),
      _QuickActionItem(
        title: 'Backup & Sync',
        icon: LucideIcons.database_backup,
        onTap: () => widget.onNavigate?.call(5), // Backup & Restore
      ),
      _QuickActionItem(
        title: 'User Settings',
        icon: LucideIcons.sliders_horizontal,
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
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder, width: 1),
      ),
      padding: const EdgeInsets.all(AppDesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: AppTypography.sectionTitle,
              ),
              SizedBox(
                width: 0,
                height: 0,
                child: Text(
                  'Get started with these Quick Actions',
                  style: TextStyle(fontSize: 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesignTokens.space16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppDesignTokens.space8,
              mainAxisSpacing: AppDesignTokens.space8,
              childAspectRatio: 2.7,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return _QuickActionButton(action: action);
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionButton extends StatefulWidget {
  final _QuickActionItem action;

  const _QuickActionButton({required this.action});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
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
          duration: AppDesignTokens.motionFast,
          padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space12),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.pageBackground : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            border: Border.all(
              color: _isHovered ? AppColors.darkCharcoal.withValues(alpha: 0.3) : AppColors.softBorder,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.action.icon,
                size: 16,
                color: AppColors.darkCharcoal,
              ),
              const SizedBox(width: AppDesignTokens.space8),
              Expanded(
                child: Text(
                  widget.action.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkCharcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
