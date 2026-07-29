import '../database_helper.dart';

class AuditRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> logAction({
    int? userId,
    String? username,
    String? role,
    required String module,
    required String action,
    required String status,
    String? description,
    String? deviceInfo,
  }) async {
    final db = await _dbHelper.database;
    return await db.insert('activity_logs', {
      'user_id': userId,
      'username': username ?? 'System',
      'role': role ?? 'System',
      'module': module,
      'action': action,
      'status': status,
      'description': description,
      'device_info': deviceInfo ?? 'Local Device',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getLogs({
    int? userId,
    String? role,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    final db = await _dbHelper.database;
    
    String where = '1 = 1';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      where += ' AND user_id = ?';
      whereArgs.add(userId);
    }

    if (role != null && role != 'All') {
      where += ' AND role = ?';
      whereArgs.add(role);
    }

    if (startDate != null && endDate != null) {
      final startIso = startDate.toIso8601String();
      // Add 1 day to end date to make it inclusive up to the end of the day
      final endIso = endDate.add(const Duration(days: 1)).toIso8601String();
      where += ' AND created_at >= ? AND created_at < ?';
      whereArgs.add(startIso);
      whereArgs.add(endIso);
    }

    if (search != null && search.isNotEmpty) {
      where += ' AND (username LIKE ? OR action LIKE ? OR module LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    return await db.query(
      'activity_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: 1000,
    );
  }
}
