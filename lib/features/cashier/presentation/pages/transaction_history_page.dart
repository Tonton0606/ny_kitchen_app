import 'package:flutter/material.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../shared/widgets/state_placeholders.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transaction History',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text('View today\'s past orders',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: MockData.transactions.isEmpty
                ? StatePlaceholders.empty(
                    message: 'No transactions yet.',
                    icon: Icons.receipt_long,
                    context: context,
                  )
                : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: MockData.transactions.length,
              itemBuilder: (context, index) {
                final tx = MockData.transactions[index];
                final isVoided = tx['status'] == 'Voided';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: cs.outlineVariant),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(24),
                    leading: CircleAvatar(
                      backgroundColor: isVoided
                          ? cs.outlineVariant
                          : cs.primary.withValues(alpha: 0.2),
                      child: Icon(
                        isVoided ? Icons.block : Icons.receipt,
                              color: isVoided
                                  ? cs.onSurfaceVariant
                                  : cs.primary,
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
                            color: isVoided ? cs.onSurfaceVariant : cs.error,
                            decoration: isVoided ? TextDecoration.lineThrough : null,
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
                                    ? cs.outlineVariant
                                    : cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tx['status'],
                                style: TextStyle(
                                  color: isVoided
                                      ? cs.onSurfaceVariant
                                      : cs.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
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
