import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';

class SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final VoidCallback? onOpenPos;

  const SalesChart({
    super.key,
    required this.data,
    this.onOpenPos,
  });

  @override
  Widget build(BuildContext context) {
    // Expected data format: [{'hour': '08:00', 'amount': 1500.0}]
    
    double maxY = 0;
    bool hasSales = false;
    for (var d in data) {
      final amount = (d['amount'] as num?)?.toDouble() ?? 0.0;
      if (amount > maxY) {
        maxY = amount;
      }
      if (amount > 0) {
        hasSales = true;
      }
    }

    if (!hasSales || data.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bar_chart_rounded,
              size: 38,
              color: AppColors.mutedBrown,
            ),
            const SizedBox(height: AppDesignTokens.space8),
            const Text(
              'No sales recorded for this period',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkCharcoal,
              ),
            ),
            const SizedBox(height: AppDesignTokens.space4),
            const Text(
              'Orders rung up at the register will appear here.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedBrown,
              ),
            ),
            if (onOpenPos != null) ...[
              const SizedBox(height: AppDesignTokens.space12),
              FilledButton.icon(
                onPressed: onOpenPos,
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
          ],
        ),
      );
    }
    
    // add some padding to maxY
    maxY = maxY * 1.2;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: AppDesignTokens.space16, top: AppDesignTokens.space16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => AppColors.darkCharcoal,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '₱${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppDesignTokens.space8),
                      child: Text(
                        data[value.toInt()]['hour'] as String,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
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
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  return Text(
                    value >= 1000 ? '${(value / 1000).toStringAsFixed(1)}k' : value.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 10,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    textAlign: TextAlign.right,
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
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: AppColors.softBorder,
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  color: AppColors.goldenYellow,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

