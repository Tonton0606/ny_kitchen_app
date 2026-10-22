import 'dart:math';

import 'package:sqflite/sqflite.dart';

/// Creates positive 63-bit IDs that stay unique across offline installations.
/// The namespace and counter are stored in local-only app_settings; that table
/// is intentionally excluded from cloud synchronization.
class SyncIdGenerator {
  static const _namespaceKey = 'local_sync_id_namespace_v1';
  static const _counterKey = 'local_sync_id_counter_v1';
  static const _sequenceBits = 23;
  static const _sequenceLimit = 1 << _sequenceBits;
  static const _randomPartLimit = 1 << 20;

  static Future<int> nextId(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    final namespaceValue = await _readSetting(txn, _namespaceKey);
    final namespace = namespaceValue == null
        ? await _createNamespace(txn, now)
        : int.tryParse(namespaceValue);

    if (namespace == null || namespace <= 0 || namespace >= (1 << 40)) {
      throw StateError('Local synchronization ID namespace is invalid.');
    }

    final counterValue = await _readSetting(txn, _counterKey);
    final counter = counterValue == null ? 0 : int.tryParse(counterValue);
    if (counter == null || counter < 0 || counter >= _sequenceLimit) {
      throw StateError('Local synchronization ID counter is invalid.');
    }

    final nextCounter = counter + 1;
    if (nextCounter >= _sequenceLimit) {
      throw StateError('This device has exhausted its local sale ID range.');
    }

    await txn.insert(
      'app_settings',
      {
        'key': _counterKey,
        'value': nextCounter.toString(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // 40 random namespace bits plus 23 monotonic counter bits fit in a
    // PostgreSQL BIGINT/SQLite signed 64-bit integer.
    return (namespace << _sequenceBits) | nextCounter;
  }

  static Future<String?> _readSetting(Transaction txn, String key) async {
    final rows = await txn.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value']?.toString();
  }

  static Future<int> _createNamespace(Transaction txn, String now) async {
    final random = Random.secure();
    var namespace =
        (random.nextInt(_randomPartLimit) << 20) |
        random.nextInt(_randomPartLimit);
    if (namespace == 0) namespace = 1;

    await txn.insert(
      'app_settings',
      {
        'key': _namespaceKey,
        'value': namespace.toString(),
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    // Read back the stored value so a pre-existing namespace always wins.
    final stored = await _readSetting(txn, _namespaceKey);
    return int.tryParse(stored ?? '') ?? namespace;
  }
}
