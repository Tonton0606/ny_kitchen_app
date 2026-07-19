import '../database_helper.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> createTransaction({
    required int userId,
    required double totalAmount,
    required double discount,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await _dbHelper.database;
    int transactionId = 0;

    await db.transaction((txn) async {
      // Generate a receipt number: YYMMDD-HHMMSS-RANDOM (could just be simple format)
      final now = DateTime.now();
      final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      
      // In a real app we'd want this to be unique. For now we use the timestamp.
      // E.g., 260719-143000
      final receiptNumber = '$dateStr-$timeStr';

      transactionId = await txn.insert('transactions', {
        'receipt_number': receiptNumber,
        'user_id': userId,
        'total_amount': totalAmount,
        'discount': discount,
        'payment_method': paymentMethod,
        'status': 'Taken', // Initial status for the kitchen workflow
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

    return transactionId;
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
    return await db.update(
      'transactions',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getActiveTransactions() async {
    final db = await _dbHelper.database;
    // Get transactions that are not fully served/completed or voided/refunded.
    // Actually we want Taken, Preparing, Ready, Served to show up maybe?
    // Let's get all that are not 'voided' or 'refunded'. 
    // And if it's 'Served', maybe we still show it in a history or just keep it around.
    return await db.query(
      'transactions',
      where: 'status IN (?, ?, ?, ?)',
      whereArgs: ['Taken', 'Preparing', 'Ready', 'Served'],
      orderBy: 'created_at ASC',
    );
  }
}
