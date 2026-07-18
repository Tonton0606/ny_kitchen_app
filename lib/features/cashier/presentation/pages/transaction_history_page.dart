import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/mock_data.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "View today's past orders",
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              itemCount: MockData.transactions.length,
              itemBuilder: (context, index) {
                final tx = MockData.transactions[index];
                final isVoided = tx['status'] == 'Voided';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  color: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    horizontalTitleGap: 12,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isVoided
                          ? Colors.grey.withValues(alpha: 0.1)
                          : Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                      child: Icon(
                        isVoided ? Icons.block : Icons.receipt,
                        color: isVoided
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tx['receiptNo'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: isVoided
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          '₱${tx['total'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isVoided
                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                : Theme.of(context).colorScheme.error,
                            decoration: isVoided
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          '${tx['date']} • ${tx['items']} Items • ${tx['payment']}',
                          style: const TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isVoided
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant
                                    : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tx['status'],
                                style: TextStyle(
                                  color: isVoided
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      // Action to view details
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
