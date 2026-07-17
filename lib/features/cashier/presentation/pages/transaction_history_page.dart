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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction History',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "View today's past orders",
                      style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: MockData.transactions.length,
              itemBuilder: (context, index) {
                final tx = MockData.transactions[index];
                final isVoided = tx['status'] == 'Voided';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side:  BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(24),
                    leading: CircleAvatar(
                      backgroundColor: isVoided
                          ? Theme.of(context).colorScheme.outlineVariant
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
                            fontWeight: FontWeight.bold,
                            decoration: isVoided
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          '₱${tx['total'].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
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
                        ),
                        const SizedBox(height: 4),
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
                                borderRadius: BorderRadius.circular(4),
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
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing:  Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
