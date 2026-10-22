import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
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
    final List<Map<String, dynamic>> periodTransactions = [];

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
        periodTransactions.add(tx);
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
        ? '$cashierCount processed sales today'
        : 'No sales recorded today';

    final topFoods = await _txRepo.getTopSellingFoods(limit: 5);
    final logs = await _auditRepo.getLogs();

    if (mounted) {
      setState(() {
        _recentTransactions = periodTransactions.take(5).toList();
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
            // Page Context & Filter Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _selectedPeriod == 'Today'
                      ? 'Today \u2022 ${DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now())}'
                      : 'Viewing ${_selectedPeriod.toLowerCase()} statistics',
                  style: AppTypography.pageSubtitle,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCleanPeriodSelector(),
                    if (widget.onSettingsTap != null) ...[
                      const SizedBox(width: AppDesignTokens.space8),
                      IconButton(
                        icon: const Icon(LucideIcons.sliders_horizontal, size: 18),
                        tooltip: 'User Settings',
                        color: AppColors.darkCharcoal,
                        onPressed: widget.onSettingsTap,
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDesignTokens.space24),

            // Hierarchical KPI Hero Section
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
                subtitle: _selectedPeriod == 'Today' ? 'Today\'s orders' : '$_selectedPeriod orders',
              ),
              const SizedBox(height: AppDesignTokens.space24),
              _buildQuickActionsCard(context),
              const SizedBox(height: AppDesignTokens.space24),
              _buildSectionCard(
                context,
                'Top Selling Foods (All time)',
                _buildTopSellingList(context),
                subtitle: 'Top 5 items, all time',
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
                          subtitle: _selectedPeriod == 'Today' ? 'Today\'s orders' : '$_selectedPeriod orders',
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
                          'Top Selling Foods (All time)',
                          _buildTopSellingList(context),
                          subtitle: 'Top 5 items, all time',
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
        if (constraints.maxWidth < 768) {
          // Mobile stack: Hero card first, then quiet secondary panel below
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroRevenueCard(),
              const SizedBox(height: AppDesignTokens.space16),
              _buildSecondaryMetricsPanel(),
            ],
          );
        } else {
          // Desktop & Tablet: Revenue as visually dominant anchor (flex 5), 3 quiet secondary metrics beside it (flex 4)
          // Both panels share IntrinsicHeight with aligned top and bottom edges and no extra outlined boxes
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildHeroRevenueCard(),
                ),
                const SizedBox(width: AppDesignTokens.space24),
                Expanded(
                  flex: 4,
                  child: _buildSecondaryMetricsPanel(),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// Visually Dominant Hero KPI Card for Revenue (42px tabular figures, flat white, no border outline)
  Widget _buildHeroRevenueCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      padding: const EdgeInsets.all(AppDesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$_selectedPeriod\'S REVENUE'.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.mutedBrown,
            ),
          ),
          const SizedBox(height: AppDesignTokens.space12),
          AnimatedSwitcher(
            duration: AppDesignTokens.motionMedium,
            child: Text(
              '₱${_periodRevenue.toStringAsFixed(2)}',
              key: ValueKey<double>(_periodRevenue),
              style: AppTypography.kpiHeroDominant,
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

  /// Quiet secondary metrics panel rendering 3 metrics as a clean stacked list (no 3 extra outlined boxes)
  Widget _buildSecondaryMetricsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space24,
        vertical: AppDesignTokens.space16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuietMetricRow(
            label: '$_selectedPeriod\'S ORDERS',
            value: '$_periodOrders',
            deltaText: _ordersDeltaText,
            isDeltaPositive: _ordersDeltaPositive,
          ),
          const Divider(height: 1, color: AppColors.softBorder),
          _buildQuietMetricRow(
            label: 'MONTHLY REVENUE',
            value: '₱${_monthlyRevenue.toStringAsFixed(2)}',
            subtitle: 'Month-to-date',
          ),
          const Divider(height: 1, color: AppColors.softBorder),
          _buildQuietMetricRow(
            label: 'CASHIERS WITH SALES TODAY',
            value: '$_activeCashiersCount',
            subtitle: _cashiersSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildQuietMetricRow({
    required String label,
    required String value,
    String? deltaText,
    bool isDeltaPositive = true,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesignTokens.space8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.mutedBrown,
                ),
              ),
              const SizedBox(height: 2),
              _buildDeltaOrSubtitle(
                deltaText: deltaText,
                isDeltaPositive: isDeltaPositive,
                fallbackSubtitle: subtitle,
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
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

  Widget _buildSectionCard(BuildContext context, String title, Widget content, {String? subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      padding: const EdgeInsets.all(AppDesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.sectionTitle,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedBrown,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (title.startsWith('Recent Transactions'))
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
              else if (title.startsWith('Recent Activities'))
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
            Text(
              'No ${_selectedPeriod.toLowerCase()} transactions',
              style: const TextStyle(
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: AppDesignTokens.space16,
              headingRowHeight: 38,
              dataRowMinHeight: 46,
              dataRowMaxHeight: 46,
              headingTextStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.mutedBrown,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.darkCharcoal,
              ),
              columns: const [
                DataColumn(label: Text('Order / Receipt')),
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Amount'), numeric: true),
                DataColumn(label: Text('Status')),
              ],
              rows: _recentTransactions.map((tx) {
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
                final orderLabel = tx['order_number'] != null
                    ? '#${tx['order_number']} (${tx['receipt_number']})'
                    : (tx['receipt_number'] ?? '');

                return DataRow(cells: [
                  DataCell(Text(
                    orderLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkCharcoal,
                    ),
                  )),
                  DataCell(Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mutedBrown,
                    ),
                  )),
                  DataCell(Text(
                    '₱${_parseAmount(tx['total_amount']).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkCharcoal,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  )),
                  DataCell(StatusBadge(text: status, color: badgeColor)),
                ]);
              }).toList(),
            ),
          ),
        );
      },
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

  /// Compact Quick Actions Card (4 essential operational shortcuts)
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
        title: 'Backup & Sync',
        icon: LucideIcons.database_backup,
        onTap: () => widget.onNavigate?.call(5), // Backup & Restore
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      padding: const EdgeInsets.all(AppDesignTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: AppTypography.sectionTitle,
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
              childAspectRatio: 3.4,
            ),
            itemBuilder: (context, index) {
              return _QuickActionButton(action: actions[index]);
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
              color: _isHovered ? AppColors.darkCharcoal.withValues(alpha: 0.25) : AppColors.softBorder,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.action.icon,
                size: 16,
                color: AppColors.darkCharcoal,
              ),
              const SizedBox(width: AppDesignTokens.space8),
              Flexible(
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
