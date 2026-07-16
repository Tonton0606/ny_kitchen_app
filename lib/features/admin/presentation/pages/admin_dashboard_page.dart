import 'package:flutter/material.dart';

import '../../../../../core/utils/responsive.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/responsive_data_table.dart';
import '../../../shared/widgets/status_badge.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      body: SingleChildScrollView(
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
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Overview of today\'s business performance',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPeriodChip(context, 'Today', 0),
                      const SizedBox(width: 8),
                      _buildPeriodChip(context, 'Week', 1),
                      const SizedBox(width: 8),
                      _buildPeriodChip(context, 'Month', 2),
                    ],
                  ),
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
              childAspectRatio: isMobile ? 3.5 : isTablet ? 2.5 : 2.0,
              children: [
                _buildStatCard(context, 
                  'Today\'s Revenue',
                  '₱14,500.00',
                  '↑ 12.5% vs yesterday',
                  Icons.attach_money,
                  AppColors.success,
                ),
                _buildStatCard(context, 
                  'Today\'s Orders',
                  '124',
                  '↑ 8.3% vs yesterday',
                  Icons.receipt_long,
                  AppColors.info,
                ),
                _buildStatCard(context, 
                  'Monthly Revenue',
                  '₱425,000.00',
                  '↑ 15.2% vs last month',
                  Icons.show_chart,
                  Theme.of(context).colorScheme.tertiary,
                ),
                _buildStatCard(context, 
                  'Active Cashiers',
                  '2',
                  'Currently on shift',
                  Icons.people,
                  Theme.of(context).colorScheme.primary,
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
                        _buildChartPlaceholder(context),
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
    );
  }

  Widget _buildPeriodChip(BuildContext context, String label, int index) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : cs.onSurfaceVariant,
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
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, Widget content) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildChartPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MockData.dailyRevenue.map((d) {
              final height = (d['amount'] as double) / 60;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: height,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    d['hour'],
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Sales Trend (Hourly)',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsTable(BuildContext context) {
    return ResponsiveDataTable(
      columns: const ['Receipt No', 'Time', 'Amount', 'Status'],
      data: MockData.transactions.take(5).toList(),
      buildRow: (tx) {
        final status = tx['status'] as String;
        final isSuccess = status == 'Completed';
        final isVoided = status == 'Voided';
        final isRefunded = status == 'Refunded';
        
        Color badgeColor;
        if (isSuccess) {
          badgeColor = AppColors.success;
        } else if (isVoided) {
          badgeColor = Theme.of(context).colorScheme.error;
        } else if (isRefunded) {
          badgeColor = Theme.of(context).colorScheme.tertiary;
        } else {
          badgeColor = Theme.of(context).colorScheme.onSurfaceVariant;
        }

        return DataRow(cells: [
          DataCell(Text(tx['receiptNo'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(Text('${tx['date'].toString().split(' ')[1]} ${tx['date'].toString().split(' ')[2]}', style: const TextStyle(fontSize: 13))),
          DataCell(Text('\u20b1${tx['total'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          DataCell(StatusBadge(text: status, color: badgeColor)),
        ]);
      },
      buildCard: (tx) {
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTopSellingList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: MockData.topSelling.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = MockData.topSelling[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '#${item['rank']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface,
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
                      item['name'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['sold']} sold',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\u20b1${(item['revenue'] as double).toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentActivitiesList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: MockData.logs.length >= 4 ? 4 : MockData.logs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final log = MockData.logs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: log['status'] == 'Success'
                      ? AppColors.success.withValues(alpha: 0.1)
                      : Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  log['status'] == 'Success'
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                  size: 20,
                  color: log['status'] == 'Success'
                      ? AppColors.success
                      : Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log['action'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${log['user']} \u2022 ${log['timestamp']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
