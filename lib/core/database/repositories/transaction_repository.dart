import '../database_helper.dart';
import '../../services/sync_service.dart';
import '../../utils/sync_id_generator.dart';
import '../../utils/repository_security_guard.dart';
import 'audit_repository.dart';

class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final SyncService _syncService = SyncService();
  final AuditRepository _auditRepo = AuditRepository();

  Future<Map<String, dynamic>> createTransaction({
    required int userId,
    double? totalAmount,
    double discount = 0,
    String paymentMethod = 'cash',
    required double amountReceived,
    required double change,
    required List<Map<String, dynamic>> items,
    int? customOrderNumber,
    String? username,
    String? role,
    String orderType = 'dine_in',
    double? packagingFee,
  }) async {
    // SEC-01: Ensure caller is authenticated and cannot forge another user's ID
    final actor = await RepositorySecurityGuard.requireAuthenticated(
      module: 'Transactions',
      action: 'Create Transaction',
    );
    final effectiveUserId = int.tryParse(actor['id']?.toString() ?? '') ??
        (actor['id'] as int?) ??
        userId;
    final effectiveUsername = actor['username'] as String? ?? username ?? 'User $effectiveUserId';
    final effectiveRole = actor['role'] as String? ?? role ?? 'cashier';

    // Server of truth: order type and packaging fee calculation (cash-only POS, no discounts)
    final normalizedOrderType = orderType.trim().toLowerCase() == 'takeout' ? 'takeout' : 'dine_in';
    final double computedPackagingFee = (normalizedOrderType == 'takeout') ? 3.00 : 0.00;
    final double itemsSubtotal = items.fold<double>(
      0.0,
      (sum, item) {
        final subtotal = item['subtotal'];
        if (subtotal is num) return sum + subtotal.toDouble();
        final price = (item['food_price'] as num?)?.toDouble() ?? 0.0;
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        return sum + (price * qty);
      },
    );
    final double authoritativeTotal = itemsSubtotal + computedPackagingFee;

    final db = await _dbHelper.database;
    int transactionId = 0;
    int orderNumber = 0;
    String finalReceiptNumber = '';

    await db.transaction((txn) async {
      final now = DateTime.now();
      final dateStr = '${now.year.toString().substring(2)}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      transactionId = await SyncIdGenerator.nextId(txn);
      finalReceiptNumber =
          '$dateStr-$timeStr-${transactionId.toRadixString(36).toUpperCase()}';

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

      await txn.insert('transactions', {
        'id': transactionId,
        'receipt_number': finalReceiptNumber,
        'order_number': orderNumber,
        'user_id': effectiveUserId,
        'order_type': normalizedOrderType,
        'packaging_fee': computedPackagingFee,
        'total_amount': authoritativeTotal,
        'discount': 0.0,
        'payment_method': 'cash',
        'amount_received': amountReceived,
        'change': change,
        'status': 'Preparing',
        'created_at': now.toIso8601String(),
      });

      for (var item in items) {
        await txn.insert('transaction_items', {
          'id': await SyncIdGenerator.nextId(txn),
          'transaction_id': transactionId,
          'food_item_id': item['food_item_id'],
          'food_name': item['food_name'],
          'food_price': item['food_price'],
          'quantity': item['quantity'],
          'subtotal': item['subtotal'],
        });
      }
    });

    // Audit transaction creation (Gap 9 / SEC-01) - authoritative session identity
    final orderTypeLabel = normalizedOrderType == 'takeout' ? 'Takeout' : 'Dine-In';
    await _auditRepo.logAction(
      userId: effectiveUserId,
      username: effectiveUsername,
      role: effectiveRole,
      module: 'Transactions',
      action: 'Transaction Created',
      status: 'Success',
      description: 'Order #$orderNumber (Receipt: $finalReceiptNumber, Type: $orderTypeLabel, Fee: ₱${computedPackagingFee.toStringAsFixed(2)}, Total: ₱${authoritativeTotal.toStringAsFixed(2)}, Method: cash)',
    );

    await _syncService.syncToCloud();
    return {
      'id': transactionId,
      'transaction_id': transactionId,
      'order_number': orderNumber,
      'receipt_number': finalReceiptNumber,
      'order_type': normalizedOrderType,
      'packaging_fee': computedPackagingFee,
      'total_amount': authoritativeTotal,
    };
  }

  Future<List<Map<String, dynamic>>> getTransactions({String status = 'completed'}) async {
    await RepositorySecurityGuard.requireAuthenticated(
      module: 'Transactions',
      action: 'View Transactions',
    );
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT 
        t.*, 
        u.full_name as cashier_name, 
        u.username as cashier_username, 
        u.role as cashier_role
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE t.status = ?
      ORDER BY t.created_at DESC
    ''', [status]);
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final actor = await RepositorySecurityGuard.requireAuthenticated(
      module: 'Transactions',
      action: 'View All Transactions',
    );
    final db = await _dbHelper.database;
    final role = (actor['role'] as String?)?.toLowerCase();

    // SEC-01 & AT02: Non-admin callers are strictly restricted to their own transactions
    if (role != 'admin') {
      final userId = actor['id'] as int?;
      if (userId != null) {
        return await db.rawQuery('''
          SELECT 
            t.*, 
            u.full_name as cashier_name, 
            u.username as cashier_username, 
            u.role as cashier_role,
            (SELECT COUNT(*) FROM transaction_items WHERE transaction_id = t.id) as item_count
          FROM transactions t
          LEFT JOIN users u ON t.user_id = u.id
          WHERE t.user_id = ?
          ORDER BY t.created_at DESC
        ''', [userId]);
      }
    }

    return await db.rawQuery('''
      SELECT 
        t.*, 
        u.full_name as cashier_name, 
        u.username as cashier_username, 
        u.role as cashier_role,
        (SELECT COUNT(*) FROM transaction_items WHERE transaction_id = t.id) as item_count
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      ORDER BY t.created_at DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTransactionItems(int transactionId) async {
    await RepositorySecurityGuard.requireAuthenticated(
      module: 'Transactions',
      action: 'View Transaction Items',
    );
    final db = await _dbHelper.database;
    return await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<int> updateTransactionStatus(int id, String newStatus, {int? userId, String? username, String? role, String? reason, String? receiptNumber}) async {
    final actor = await RepositorySecurityGuard.requireAuthenticated(
      module: 'Transactions',
      action: 'Update Transaction Status',
    );

    final db = await _dbHelper.database;
    final Map<String, dynamic> updateValues = {'status': newStatus};
    if (newStatus == 'Voided' && reason != null && reason.trim().isNotEmpty) {
      updateValues['void_reason'] = reason.trim();
    } else if (newStatus == 'Refunded' && reason != null && reason.trim().isNotEmpty) {
      updateValues['refund_reason'] = reason.trim();
    }

    int count = await db.update(
      'transactions',
      updateValues,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0 && receiptNumber != null && receiptNumber.trim().isNotEmpty) {
      count = await db.update(
        'transactions',
        updateValues,
        where: 'receipt_number = ?',
        whereArgs: [receiptNumber.trim()],
      );
    }

    if (count == 0) {
      return 0;
    }

    // Audit status update - authoritative actor identity
    await _auditRepo.logAction(
      userId: actor['id'] as int?,
      username: actor['username'] as String? ?? username ?? 'System',
      role: actor['role'] as String? ?? role ?? 'System',
      module: 'Transactions',
      action: newStatus == 'Voided'
          ? 'Transaction Voided'
          : newStatus == 'Refunded'
              ? 'Transaction Refunded'
              : 'Transaction Status Updated',
      status: 'Success',
      description: 'Transaction ID $id status changed to $newStatus${reason != null ? ' ($reason)' : ''}',
    );

    await _syncService.syncToCloud();
    return count;
  }

  Future<int> cancelOrder(int id, {String? reason, int? userId, String? username, String? role, String? receiptNumber}) async {
    final actor = await RepositorySecurityGuard.requireAuthenticated(
      module: 'Transactions',
      action: 'Cancel Order',
    );
    final db = await _dbHelper.database;
    final voidReason = reason ?? 'Cancelled by cashier';
    int count = await db.update(
      'transactions',
      {'status': 'Voided', 'void_reason': voidReason},
      where: 'id = ?',
      whereArgs: [id],
    );

    if (count == 0 && receiptNumber != null && receiptNumber.trim().isNotEmpty) {
      count = await db.update(
        'transactions',
        {'status': 'Voided', 'void_reason': voidReason},
        where: 'receipt_number = ?',
        whereArgs: [receiptNumber.trim()],
      );
    }

    if (count == 0) {
      return 0;
    }

    // Audit transaction cancellation / void (Gap 9 / SEC-01) - authoritative actor identity
    await _auditRepo.logAction(
      userId: actor['id'] as int?,
      username: actor['username'] as String? ?? username ?? 'Cashier',
      role: actor['role'] as String? ?? role ?? 'cashier',
      module: 'Transactions',
      action: 'Transaction Voided',
      status: 'Success',
      description: 'Order ID $id voided: $voidReason',
    );

    await _syncService.syncToCloud();
    return count;
  }


  Future<List<Map<String, dynamic>>> getActiveTransactions() async {
    final db = await _dbHelper.database;
    // Active orders in the kitchen queue are restricted to today's business day:
    // Only 'Preparing' and 'Served' orders placed today appear in the active kitchen queue.
    // Cutoff/unserved orders from previous days remain permanently recorded in transaction history and admin sales reports.
    return await db.rawQuery('''
      SELECT 
        t.*, 
        u.full_name as cashier_name, 
        u.username as cashier_username, 
        u.role as cashier_role
      FROM transactions t
      LEFT JOIN users u ON t.user_id = u.id
      WHERE (date(t.created_at) = date('now', 'localtime') OR date(t.created_at, 'localtime') = date('now', 'localtime'))
        AND t.status IN ('Preparing', 'Served')
      ORDER BY t.created_at ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTopSellingFoods({int limit = 5}) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT 
        ti.food_name as name, 
        SUM(ti.quantity) as sold, 
        SUM(ti.subtotal) as revenue,
        fi.image_path
      FROM transaction_items ti
      JOIN transactions t ON ti.transaction_id = t.id
      LEFT JOIN food_items fi ON ti.food_item_id = fi.id
      WHERE t.status NOT IN ('Voided', 'Refunded')
      GROUP BY ti.food_name, fi.image_path
      ORDER BY sold DESC
      LIMIT ?
    ''', [limit]);
    return result;
  }
}
