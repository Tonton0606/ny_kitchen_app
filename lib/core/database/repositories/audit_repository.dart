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
    String? role,
    String? date, // Format 'YYYY-MM-DD'
    String? search,
  }) async {
    final db = await _dbHelper.database;
    
    String where = '1 = 1';
    List<dynamic> whereArgs = [];

    if (role != null && role != 'All') {
      where += ' AND role = ?';
      whereArgs.add(role);
    }

    if (date != null && date == 'Today') {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      where += ' AND created_at LIKE ?';
      whereArgs.add('$dateStr%');
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
