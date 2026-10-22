import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';

class SalesChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback? onOpenPos;

  const SalesChart({
    super.key,
    required this.data,
    this.onOpenPos,
  });

  @override
  State<SalesChart> createState() => _SalesChartState();
}

class _SalesChartState extends State<SalesChart> {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₱',
    decimalDigits: 2,
  );

  int _touchedIndex = -1;

  (double, double) _computeCleanAxis(double maxVal) {
    if (maxVal <= 0) return (400.0, 100.0);
    // Steps of 50, 100, 200 or 500 whichever gives 4-5 intervals
    final candidateSteps = [
      50.0, 100.0, 200.0, 500.0,
      1000.0, 2000.0, 5000.0, 10000.0, 20000.0, 50000.0
    ];
    for (final step in candidateSteps) {
      final intervals = (maxVal / step).ceil();
      if (intervals >= 3 && intervals <= 5) {
        final count = intervals < 4 ? 4 : intervals;
        return (count * step, step);
      }
    }
    final step = candidateSteps.firstWhere(
      (s) => s * 4 >= maxVal,
      orElse: () => 50000.0,
    );
    return (step * 4, step);
  }

  @override
  Widget build(BuildContext context) {
    double rawMax = 0;
    bool hasSales = false;
    for (var d in widget.data) {
      final amount = (d['amount'] as num?)?.toDouble() ?? 0.0;
      if (amount > rawMax) {
        rawMax = amount;
      }
      if (amount > 0) {
        hasSales = true;
      }
    }

    if (!hasSales || widget.data.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 38,
              color: AppColors.mutedSlate,
            ),
            SizedBox(height: AppDesignTokens.space8),
            Text(
              'No sales recorded for this period',
              style: AppTypography.heading,
            ),
            SizedBox(height: AppDesignTokens.space4),
            Text(
              'Orders rung up at the register will appear here.',
              style: AppTypography.label12,
            ),
          ],
        ),
      );
    }

    final (maxY, interval) = _computeCleanAxis(rawMax);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool showEveryTwoHours = constraints.maxWidth < 700;
        final double barWidth = constraints.maxWidth >= 700 ? 28.0 : 24.0;

        return SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchCallback: (event, response) {
                  setState(() {
                    if (event is FlTapUpEvent || event is FlPanEndEvent || response == null || response.spot == null) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex = response.spot!.touchedBarGroupIndex;
                    }
                  });
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.darkCharcoal,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = widget.data[group.x.toInt()];
                    final hour = item['hour'] ?? '';
                    final amount = _currencyFormat.format(rod.toY);
                    return BarTooltipItem(
                      '$hour · $amount',
                      const TextStyle(
                        fontFamily: AppTypography.displayFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < widget.data.length) {
                        // Slot width equals label width: one per hour, or every 2 hours if narrow
                        if (showEveryTwoHours && idx % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: AppDesignTokens.space8),
                          child: Text(
                            widget.data[idx]['hour'] as String,
                            style: AppTypography.label.copyWith(fontSize: 10, letterSpacing: 0.0),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      if (value < -0.1 || value > maxY + 0.1) return const SizedBox.shrink();
                      final formatted = value == 0
                          ? '₱0'
                          : value >= 1000 && value % 1000 == 0
                              ? '₱${(value / 1000).toStringAsFixed(0)}k'
                              : value >= 1000
                                  ? '₱${(value / 1000).toStringAsFixed(1)}k'
                                  : '₱${value.toInt()}';
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          formatted,
                          style: AppTypography.figureCustom(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedSlate,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                checkToShowHorizontalLine: (value) => true,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: AppColors.softBorder,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  );
                },
              ),
              barGroups: widget.data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                final isHovered = _touchedIndex == index;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: amount,
                      color: isHovered ? AppColors.goldDeep : AppColors.goldenYellow,
                      width: barWidth,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
