import '../database_helper.dart';
import '../../services/sync_service.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();

  Future<Map<String, dynamic>> createTransaction({
    required int userId,
    required double totalAmount,
    required double discount,
    required String paymentMethod,
    required double amountReceived,
    required double change,
    required List<Map<String, dynamic>> items,
    int? customOrderNumber,
  }) async {
    final db = await _dbHelper.database;
    int transactionId = 0;
    int orderNumber = 0;

    await db.transaction((txn) async {
      final now = DateTime.now();
      final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final receiptNumber = '$dateStr-$timeStr';

      // Calculate daily order number
      if (customOrderNumber != null) {
        orderNumber = customOrderNumber;
      } else {
        final todayPrefix = now.toIso8601String().substring(0, 10);
        final countResult = await txn.rawQuery(
          "SELECT COUNT(*) as count FROM transactions WHERE created_at LIKE ?",
          ['$todayPrefix%'],
        );
        orderNumber = (countResult.first['count'] as int? ?? 0) + 1;
      }

      transactionId = await txn.insert('transactions', {
        'receipt_number': receiptNumber,
        'order_number': orderNumber,
        'user_id': userId,
        'total_amount': totalAmount,
        'discount': discount,
        'payment_method': paymentMethod,
        'amount_received': amountReceived,
        'change': change,
        'status': 'Preparing',
        'created_at': now.toIso8601String(),
      });

      for (var item in items) {
        await txn.insert('transaction_items', {
          'transaction_id': transactionId,
          'food_item_id': item['food_item_id'],
          'food_name': item['food_name'],
          'food_price': item['food_price'],
          'quantity': item['quantity'],
          'subtotal': item['subtotal'],
        });
      }
    });

    await _syncService.syncToCloud();
    return {'transaction_id': transactionId, 'order_number': orderNumber};
  }

  Future<List<Map<String, dynamic>>> getTransactions({String status = 'completed'}) async {
    final db = await _dbHelper.database;
    return await db.query(
      'transactions',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await _dbHelper.database;
    return await db.query(
      'transactions',
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionItems(int transactionId) async {
    final db = await _dbHelper.database;
    return await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<int> updateTransactionStatus(int id, String newStatus) async {
    final db = await _dbHelper.database;
    int count = await db.update(
      'transactions',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.syncToCloud();
    return count;
  }

  Future<int> cancelOrder(int id, {String? reason}) async {
    final db = await _dbHelper.database;
    int count = await db.update(
      'transactions',
      {'status': 'Voided', 'void_reason': reason ?? 'Cancelled by cashier'},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncService.syncToCloud();
    return count;
  }

  Future<List<Map<String, dynamic>>> getActiveTransactions() async {
    final db = await _dbHelper.database;
    // Get transactions that are not fully served/completed or voided/refunded.
    // Actually we want Taken, Preparing, Ready, Served to show up maybe?
    // Let's get all that are not 'voided' or 'refunded'. 
    // And if it's 'Served', maybe we still show it in a history or just keep it around.
    return await db.query(
      'transactions',
      where: 'status IN (?, ?)',
      whereArgs: ['Preparing', 'Served'],
      orderBy: 'created_at ASC',
    );
  }
}
