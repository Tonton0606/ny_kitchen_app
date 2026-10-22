import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/database/repositories/transaction_repository.dart';
import '../shared/widgets/sales_chart.dart';
import '../../../../../core/services/sync_service.dart';


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
  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _topSellingFoods = [];

  String _selectedPeriod = 'Today'; // 'Today', 'Week', 'Month'
  double _periodRevenue = 0;
  int _periodOrders = 0;
  double _monthlyRevenue = 0;
  List<Map<String, dynamic>> _hourlyData = [];
  String? _peakHour;

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
    SyncService.onSyncCompletedNotifier.addListener(_loadDashboardData);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    SyncService.onSyncCompletedNotifier.removeListener(_loadDashboardData);
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

    String? peakHr;
    double maxHourRev = 0;
    final chartData = hourlyRev.entries.map((e) {
      if (e.value > maxHourRev && e.value > 0) {
        maxHourRev = e.value;
        peakHr = '${e.key > 12 ? e.key - 12 : e.key} ${e.key >= 12 ? 'PM' : 'AM'}';
      }
      final hourStr = '${e.key > 12 ? e.key - 12 : e.key} ${e.key >= 12 ? 'PM' : 'AM'}';
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

    if (mounted) {
      setState(() {
        _recentTransactions = periodTransactions.take(5).toList();
        _periodRevenue = pRev;
        _periodOrders = pOrders;
        _monthlyRevenue = mRev;
        _hourlyData = chartData;
        _peakHour = peakHr;
        _revenueDeltaText = revDelta;
        _revenueDeltaPositive = revPositive;
        _ordersDeltaText = ordDelta;
        _ordersDeltaPositive = ordPositive;
        _activeCashiersCount = cashierCount;
        _cashiersSubtitle = cashierSub;
        _topSellingFoods = topFoods;
        _isLoading = false;
      });
    }
  }

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 2,
  );

  String _formatCurrency(num amount) => _currencyFormat.format(amount);

  String _getDateLineText() {
    final now = DateTime.now();
    if (_selectedPeriod == 'Today') {
      return DateFormat('EEEE, MMMM d, yyyy').format(now).toUpperCase();
    } else if (_selectedPeriod == 'Week') {
      final start = now.subtract(const Duration(days: 7));
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d, yyyy').format(now)}'.toUpperCase();
    } else {
      return DateFormat('MMMM yyyy').format(now).toUpperCase();
    }
  }

  String? _getSalesTrendSubtitle() {
    if (_periodOrders <= 0 || _periodRevenue <= 0) return null;
    final orderWord = _periodOrders == 1 ? 'order' : 'orders';
    final peakPart = _peakHour != null ? ' · peak $_peakHour' : '';
    return '${_formatCurrency(_periodRevenue)} from $_periodOrders $orderWord$peakPart';
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
                  _getDateLineText(),
                  style: AppTypography.label,
                ),
                _buildCleanPeriodSelector(),
              ],
            ),
            const SizedBox(height: AppDesignTokens.space16),

            // Main Content Layout: Two independent columns starting at the same top edge
            if (isMobile) ...[
              _buildHeroRevenueCard(),
              const SizedBox(height: AppDesignTokens.space16),
              _buildSecondaryMetricsPanel(),
              const SizedBox(height: AppDesignTokens.space16),
              _buildQuickActionsStrip(context),
              const SizedBox(height: AppDesignTokens.space16),
              _buildSectionCard(
                context,
                'Sales Trend',
                _isLoading
                    ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
                    : SalesChart(data: _hourlyData),
                subtitle: _getSalesTrendSubtitle(),
              ),
              const SizedBox(height: AppDesignTokens.space16),
              _buildSectionCard(
                context,
                'Recent Transactions',
                _buildRecentTransactionsTable(context),
                subtitle: _selectedPeriod == 'Today' ? 'Today\'s orders' : '$_selectedPeriod orders',
                trailing: _ViewAllButton(onTap: () => widget.onNavigate?.call(1)),
              ),
              const SizedBox(height: AppDesignTokens.space16),
              _buildSectionCard(
                context,
                'Top Selling Foods',
                _buildTopSellingList(context),
                subtitle: 'Top 5 items, all time',
              ),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column (wider, flex 5): Hero Revenue, Sales Trend, Recent Transactions
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroRevenueCard(),
                        const SizedBox(height: AppDesignTokens.space16),
                        _buildSectionCard(
                          context,
                          'Sales Trend',
                          _isLoading
                              ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()))
                              : SalesChart(data: _hourlyData),
                          subtitle: _getSalesTrendSubtitle(),
                        ),
                        const SizedBox(height: AppDesignTokens.space16),
                        _buildSectionCard(
                          context,
                          'Recent Transactions',
                          _buildRecentTransactionsTable(context),
                          subtitle: _selectedPeriod == 'Today' ? 'Today\'s orders' : '$_selectedPeriod orders',
                          trailing: _ViewAllButton(onTap: () => widget.onNavigate?.call(1)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.space24),
                  // Right Column (flex 4): Stats list, Quick Actions strip, Top Selling Foods
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSecondaryMetricsPanel(),
                        const SizedBox(height: AppDesignTokens.space16),
                        _buildQuickActionsStrip(context),
                        const SizedBox(height: AppDesignTokens.space16),
                        _buildSectionCard(
                          context,
                          'Top Selling Foods',
                          _buildTopSellingList(context),
                          subtitle: 'Top 5 items, all time',
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesignTokens.space12,
          vertical: AppDesignTokens.space4 + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldenYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
        ),
        child: Text(
          label,
          style: isSelected
              ? AppTypography.buttonSmall.copyWith(fontWeight: FontWeight.w800)
              : AppTypography.buttonSmall,
        ),
      ),
    );
  }

  /// Hero KPI Card for Revenue (150-170px height, Average Order baseline-aligned, no divider)
  Widget _buildHeroRevenueCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space24,
        vertical: AppDesignTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_selectedPeriod\'S REVENUE'.toUpperCase(),
                style: AppTypography.label,
              ),
              const Text(
                'AVERAGE ORDER',
                style: AppTypography.label,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppDesignTokens.motionMedium,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      ...previousChildren,
                      ?currentChild,
                    ],
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatCurrency(_periodRevenue),
                      key: ValueKey<double>(_periodRevenue),
                      style: AppTypography.figureHero,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDesignTokens.space16),
              Text(
                _formatCurrency(_periodOrders > 0 ? (_periodRevenue / _periodOrders) : 0.0),
                style: AppTypography.figure,
              ),
            ],
          ),
          _buildDeltaOrSubtitle(
            deltaText: _revenueDeltaText,
            isDeltaPositive: _revenueDeltaPositive,
            isHero: true,
          ),
        ],
      ),
    );
  }

  /// Quiet secondary metrics panel rendering 3 metrics matching Hero's height
  Widget _buildSecondaryMetricsPanel() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesignTokens.space24,
        vertical: AppDesignTokens.space16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuietMetricRow(
            label: '$_selectedPeriod\'S ORDERS',
            value: '$_periodOrders',
            deltaText: _ordersDeltaText == 'No previous data' ? null : _ordersDeltaText,
            isDeltaPositive: _ordersDeltaPositive,
          ),
          const Divider(height: 1, color: AppColors.softBorder),
          _buildQuietMetricRow(
            label: 'MONTHLY REVENUE',
            value: _formatCurrency(_monthlyRevenue),
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
    final hasSubtext = (deltaText != null && deltaText.isNotEmpty) || (subtitle != null && subtitle.isNotEmpty);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.label,
            ),
            if (hasSubtext) ...[
              const SizedBox(height: 2),
              _buildDeltaOrSubtitle(
                deltaText: deltaText,
                isDeltaPositive: isDeltaPositive,
                fallbackSubtitle: subtitle,
                isHero: false,
              ),
            ],
          ],
        ),
        Text(
          value,
          style: AppTypography.figure,
        ),
      ],
    );
  }

  Widget _buildDeltaOrSubtitle({
    String? deltaText,
    bool isDeltaPositive = true,
    String? fallbackSubtitle,
    bool isHero = false,
  }) {
    if (deltaText != null) {
      if (deltaText == 'No previous data') {
        if (!isHero) return const SizedBox.shrink();
        return const Text(
          'No previous data',
          style: AppTypography.label12,
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
            style: AppTypography.label12.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    if (fallbackSubtitle != null && fallbackSubtitle.isNotEmpty) {
      return Text(
        fallbackSubtitle,
        style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    Widget content, {
    String? subtitle,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      padding: const EdgeInsets.all(AppDesignTokens.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.heading,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
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
        height: 160,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.receipt, size: 36, color: AppColors.mutedSlate),
            SizedBox(height: AppDesignTokens.space8),
            Text(
              'No transactions for this period',
              style: AppTypography.heading,
            ),
            SizedBox(height: AppDesignTokens.space4),
            Text(
              'Completed orders will appear here automatically.',
              style: AppTypography.label12,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Table Header (Label role)
        Padding(
          padding: const EdgeInsets.only(bottom: AppDesignTokens.space8),
          child: Row(
            children: const [
              Expanded(
                child: Text('ORDER', style: AppTypography.label),
              ),
              SizedBox(
                width: 100,
                child: Text('TIME', style: AppTypography.label),
              ),
              SizedBox(
                width: 100,
                child: Text('AMOUNT', style: AppTypography.label, textAlign: TextAlign.right),
              ),
              SizedBox(
                width: 110,
                child: Text('STATUS', style: AppTypography.label, textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        // Rows (52-56px height, first 5 loaded rows display-only)
        for (final tx in _recentTransactions.take(5)) ...[
          Container(
            height: 54,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.softBorder, width: 1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final orderNum = tx['order_number'] != null ? '#${tx['order_number']}' : '';
                      final receiptNum = tx['receipt_number'] as String? ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            orderNum.isNotEmpty ? orderNum : receiptNum,
                            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (orderNum.isNotEmpty && receiptNum.isNotEmpty)
                            Text(
                              receiptNum,
                              style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Builder(
                    builder: (context) {
                      final parsedDate = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
                      return Text(
                        DateFormat('h:mm a').format(parsedDate),
                        style: AppTypography.body.copyWith(fontSize: 14, color: AppColors.mutedSlate),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    _formatCurrency(_parseAmount(tx['total_amount'])),
                    style: AppTypography.figureCustom(fontSize: 15),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _buildTransactionStatusChip(tx['status'] as String? ?? 'Unknown'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTransactionStatusChip(String status) {
    final isServed = status == 'Completed' || status == 'Served';
    final isCancelled = status == 'Voided' || status == 'Cancelled';
    final isRefunded = status == 'Refunded';

    final Color dotColor;
    final Color textColor;
    final Color bgColor;

    if (isServed) {
      dotColor = AppColors.forest;
      textColor = AppColors.forest;
      bgColor = AppColors.forest.withValues(alpha: 0.12);
    } else if (isCancelled) {
      dotColor = AppColors.brandRed;
      textColor = AppColors.brandRed;
      bgColor = AppColors.brandRed.withValues(alpha: 0.12);
    } else if (isRefunded) {
      dotColor = AppColors.mutedSlate;
      textColor = AppColors.darkCharcoal;
      bgColor = AppColors.darkCharcoal.withValues(alpha: 0.08);
    } else {
      dotColor = AppColors.mutedSlate;
      textColor = AppColors.darkCharcoal;
      bgColor = AppColors.pageBackground;
    }

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: AppTypography.body.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
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
            style: AppTypography.bodyMuted,
          ),
        ),
      );
    }

    final maxSold = (_topSellingFoods.isNotEmpty
        ? (_topSellingFoods.first['sold'] as num?)?.toDouble() ?? 1.0
        : 1.0);

    return Column(
      children: [
        for (int index = 0; index < _topSellingFoods.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.softBorder),
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.goldenYellow,
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: AppTypography.figureSmall,
                  ),
                ),
                const SizedBox(width: AppDesignTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (_topSellingFoods[index]['name'] as String? ?? 'Unknown Item').trim(),
                        style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final sold = (_topSellingFoods[index]['sold'] as num?)?.toDouble() ?? 0.0;
                          final ratio = maxSold > 0 ? (sold / maxSold).clamp(0.05, 1.0) : 0.05;
                          return Container(
                            height: 4,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: AppColors.goldenYellow.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDesignTokens.space12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatCurrency(_parseAmount(_topSellingFoods[index]['revenue'])),
                      style: AppTypography.figureCustom(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_topSellingFoods[index]['sold']} sold',
                      style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Slim Quick Actions Strip: one row of 4 compact buttons with small "QUICK ACTIONS" caption above
  Widget _buildQuickActionsStrip(BuildContext context) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: AppTypography.label,
        ),
        const SizedBox(height: AppDesignTokens.space8),
        SizedBox(
          height: 38,
          child: Row(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: AppDesignTokens.space8),
                Expanded(child: _QuickActionButton(action: actions[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ViewAllButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewAllButton({required this.onTap});

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppDesignTokens.motionFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesignTokens.space8,
            vertical: AppDesignTokens.space4,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.goldenYellow.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View all',
                style: AppTypography.button.copyWith(
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(width: AppDesignTokens.space4),
              const Icon(
                LucideIcons.chevron_right,
                size: 16,
                color: AppColors.darkCharcoal,
              ),
            ],
          ),
        ),
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
    return Tooltip(
      message: widget.action.title,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.action.onTap,
          child: AnimatedContainer(
            duration: AppDesignTokens.motionFast,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space12),
            decoration: BoxDecoration(
              color: _isHovered
                  ? AppColors.goldenYellow.withValues(alpha: 0.25)
                  : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.action.icon,
                  size: 15,
                  color: AppColors.darkCharcoal,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.action.title,
                    style: AppTypography.button.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
