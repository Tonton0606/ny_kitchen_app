// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import '../utils/sync_id_generator.dart';
import '../utils/security_utils.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'backend_sync_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SyncService {
  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // Selected once at startup. A failed backend setup must not fall back to cloud.
  static bool backendMode = false;

  /// Sync mode: 'manual' (default) or 'automatic'
  static String syncMode = 'manual';
  static final ValueNotifier<String> syncModeNotifier = ValueNotifier<String>('manual');

  /// Event notifier triggered when a full sync finishes so UI pages can auto-refresh
  static final ValueNotifier<int> onSyncCompletedNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<String> syncStatusNotifier =
      ValueNotifier<String>('Not synchronized');

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured {
    if (backendMode) return BackendSyncService.instance != null;
    return _supabase != null;
  }
  
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // List of tables to sync in order of dependency (parents first)
  final List<String> _tables = [
    'users',
    'food_categories',
    'food_items',
    'transactions',
    'transaction_items',
    'activity_logs',
    'login_attempts',
  ];

  Timer? _syncTimer;
  Future<void> _operationQueue = Future<void>.value();
  Future<bool>? _activeFullSync;
  String? _lastUploadFailure;
  String? _lastDownloadFailure;
  int _legacyTransactionIdsRepaired = 0;

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _operationQueue.then((_) => operation());
    _operationQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace stack) {},
    );
    return result;
  }

  String _safeErrorCode(Object error) {
    final errorText = error.toString();
    final code = RegExp(r'\bPGRST\d+\b|\b[0-9A-Z]{5}\b').firstMatch(errorText)?.group(0);
    if (code == '23502') {
      // A not-null error may safely expose the column identifier, never the
      // database row or the rest of the server error (which can contain data).
      final column = RegExp(
        r'null value in column "([A-Za-z_][A-Za-z0-9_]*)"',
        caseSensitive: false,
      ).firstMatch(errorText)?.group(1);
      if (column != null) return '$code ($column required)';
    } else if (code == 'PGRST204') {
      final column = RegExp(
        r"Could not find the column '([A-Za-z_][A-Za-z0-9_]*)'",
        caseSensitive: false,
      ).firstMatch(errorText)?.group(1);
      if (column != null) return '$code (unknown column $column)';
    }
    return code ?? error.runtimeType.toString();
  }

  static const _transactionIdentityColumns =
      'id, receipt_number, created_at, total_amount, discount, payment_method';

  static bool _sameSaleIdentity(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final localReceipt = local['receipt_number']?.toString();
    final cloudReceipt = cloud['receipt_number']?.toString();
    if (localReceipt == null || localReceipt.isEmpty || localReceipt != cloudReceipt) {
      return false;
    }

    double? number(Object? value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    bool sameNumber(Object? left, Object? right, {double fallback = 0}) {
      final leftNumber = number(left) ?? fallback;
      final rightNumber = number(right) ?? fallback;
      return (leftNumber - rightNumber).abs() < 0.005;
    }

    if (!sameNumber(local['total_amount'], cloud['total_amount']) ||
        !sameNumber(local['discount'], cloud['discount']) ||
        local['payment_method']?.toString() !=
            cloud['payment_method']?.toString()) {
      return false;
    }

    final localTime = DateTime.tryParse(local['created_at']?.toString() ?? '');
    final cloudTime = DateTime.tryParse(cloud['created_at']?.toString() ?? '');
    if (localTime != null && cloudTime != null) {
      if (localTime.isAtSameMomentAs(cloudTime)) return true;
      // Handle local timezone (no offset) vs cloud UTC (+00:00) representation differences
      final localIso = (local['created_at']?.toString() ?? '').replaceAll('Z', '').split('+').first;
      final cloudIso = (cloud['created_at']?.toString() ?? '').replaceAll('Z', '').split('+').first;
      if (localIso == cloudIso) return true;
      final diff = localTime.toUtc().difference(cloudTime.toUtc()).abs();
      if (diff.inHours <= 24) return true;
    }
    // Matching unique receipt number, total, discount, and payment method definitively establishes the same sale identity
    return true;
  }

  Future<int> _repairLegacyTransactionIdCollisions(
    SupabaseClient client,
    Database db,
  ) async {
    final localRows = await db.query(
      'transactions',
      columns: [
        'id',
        'receipt_number',
        'created_at',
        'total_amount',
        'discount',
        'payment_method',
      ],
    );
    if (localRows.isEmpty) return 0;

    final cloudById = <int, Map<String, dynamic>>{};
    const batchSize = 100;
    for (var start = 0; start < localRows.length; start += batchSize) {
      final end = start + batchSize < localRows.length
          ? start + batchSize
          : localRows.length;
      final ids = localRows
          .sublist(start, end)
          .map((row) => row['id'] as int)
          .toList();
      final cloudRows = await client
          .from('transactions')
          .select(_transactionIdentityColumns)
          .inFilter('id', ids);
      for (final row in cloudRows) {
        final id = int.tryParse(row['id']?.toString() ?? '');
        if (id != null) cloudById[id] = Map<String, dynamic>.from(row);
      }
    }

    final conflicts = localRows.where((local) {
      final cloud = cloudById[local['id'] as int];
      return cloud != null && !_sameSaleIdentity(local, cloud);
    }).map((row) => row['id'] as int).toList();
    if (conflicts.isEmpty) return 0;

    return db.transaction((txn) async {
      var repaired = 0;
      for (final oldId in conflicts) {
        final currentRows = await txn.query(
          'transactions',
          where: 'id = ?',
          whereArgs: [oldId],
          limit: 1,
        );
        final cloud = cloudById[oldId];
        if (currentRows.isEmpty ||
            cloud == null ||
            _sameSaleIdentity(currentRows.first, cloud)) {
          continue;
        }
        await _rekeyLocalTransaction(txn, oldId);
        repaired++;
      }
      return repaired;
    });
  }

  Future<void> _rekeyLocalTransaction(Transaction txn, int oldId) async {
    final rows = await txn.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [oldId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final transaction = Map<String, dynamic>.from(rows.first);
    final items = await txn.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [oldId],
      orderBy: 'id',
    );

    // Move the child rows before removing the old parent, then reinsert the
    // sale and its items under IDs that cannot collide with another device.
    await txn.delete(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [oldId],
    );
    await txn.delete('transactions', where: 'id = ?', whereArgs: [oldId]);

    final newId = await SyncIdGenerator.nextId(txn);
    transaction['id'] = newId;
    await txn.insert('transactions', transaction);

    for (final item in items) {
      final movedItem = Map<String, dynamic>.from(item)
        ..['id'] = await SyncIdGenerator.nextId(txn)
        ..['transaction_id'] = newId;
      await txn.insert('transaction_items', movedItem);
    }
  }

  /// Loads saved sync mode from app_settings and starts timer if set to automatic
  Future<void> initSyncMode() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['sync_mode'],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        final mode = maps.first['value'] as String? ?? 'manual';
        setSyncMode(mode, persist: false);
      } else {
        setSyncMode('manual', persist: false);
      }
    } catch (_) {
      setSyncMode('manual', persist: false);
    }
  }

  /// Sets the sync mode ('manual' or 'automatic') and updates persistent storage
  Future<void> setSyncMode(String mode, {bool persist = true}) async {
    syncMode = mode;
    syncModeNotifier.value = mode;

    if (mode == 'automatic') {
      startAutomaticSync(intervalSeconds: 15);
    } else {
      stopAutomaticSync();
    }

    if (persist) {
      try {
        final db = await _dbHelper.database;
        await db.insert(
          'app_settings',
          {
            'key': 'sync_mode',
            'value': mode,
            'updated_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (_) {}
    }
  }

  /// Starts an automatic periodic 2-way sync across all devices
  void startAutomaticSync({int intervalSeconds = 15}) {
    _syncTimer?.cancel();
    if (!isConfigured) {
      syncStatusNotifier.value = 'Automatic sync unavailable: cloud not configured';
      return;
    }
    // Run initial 2-way sync immediately
    fullSync();
    // Then repeat periodically
    _syncTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      fullSync();
    });
  }

  void stopAutomaticSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Strips sensitive credentials (password_hash) and residual columns before syncing to cloud.
  static Map<String, dynamic> sanitizeUserForCloudSync(Map<String, dynamic> record) {
    final sanitized = Map<String, dynamic>.from(record);
    sanitized.remove('password_hash');
    sanitized.remove('face_encoding');
    return sanitized;
  }

  /// Merges a cloud user profile without importing credentials.
  /// Existing users keep device-local auth state; newly imported profiles get
  /// a random local-only hash and require an Admin password reset on this device.
  static Map<String, dynamic> mergePulledUserRecord(
    Map<String, dynamic> cloudRecord,
    Map<String, dynamic>? existingLocal,
  ) {
    final merged = Map<String, dynamic>.from(cloudRecord);
    // Cloud sync carries user profiles only. Never accept cloud credentials or residual fields.
    merged.remove('password_hash');
    merged.remove('face_encoding');
    if (existingLocal != null) {
      merged['failed_login_count'] = existingLocal['failed_login_count'];
      merged['password_hash'] = existingLocal['password_hash'];
      merged['last_login'] = existingLocal['last_login'];
      merged['must_change_password'] = existingLocal['must_change_password'];

      // Sticky administrative & account security status:
      // If a user account has been disabled ('inactive') or locked out ('locked') locally,
      // a lagged or stale cloud sync pull must never resurrect it back to 'active'.
      final localStatus = existingLocal['status'] as String?;
      final cloudStatus = cloudRecord['status'] as String?;
      if ((localStatus == 'inactive' || localStatus == 'locked') && cloudStatus == 'active') {
        merged['status'] = localStatus;
      }
    } else {
      // A profile pulled to a new device has no local credential yet. Store an
      // unguessable device-only hash so the account cannot log in until an
      // administrator sets a local password through Account Management.
      merged['password_hash'] = SecurityUtils.hashPassword(
        SecurityUtils.generateSalt(32),
      );
      merged['failed_login_count'] = 0;
      merged['last_login'] = null;
      merged['must_change_password'] = 1;
    }
    return merged;
  }

  /// Uploads a local image file to Supabase Storage and returns the public URL
  Future<String?> uploadImage(String localPath) async {
    if (backendMode) return localPath;
    try {
      if (localPath.startsWith('http')) return localPath; // Already a URL
      if (localPath.isEmpty) return null;

      final file = File(localPath);
      if (!await file.exists()) {
        return localPath; // Return as-is if it's not a local file we can find
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}';
      await _supabase?.storage
          .from('food_images')
          .upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeFor(localPath),
            ),
          );

      return _supabase?.storage.from('food_images').getPublicUrl(fileName);
    } catch (_) {
      return localPath; // fallback to local path if upload fails
    }
  }

  String _contentTypeFor(String localPath) {
    switch (path.extension(localPath).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  /// Queues a cloud upload. Ubuntu mode intentionally queues without blocking
  /// checkout; fullSync awaits its own single backend operation.
  Future<bool> syncToCloud() async {
    if (backendMode) {
      final backend = BackendSyncService.instance;
      if (backend == null) {
        syncStatusNotifier.value = 'Upload unavailable: backend not configured';
        return false;
      }
      unawaited(_enqueue(() => backend.sync()).then<void>((_) {}));
      return true;
    }

    return _enqueue(_syncToSupabase);
  }

  Future<bool> _syncToSupabase() async {
    final client = _supabase;
    if (client == null) {
      _lastUploadFailure = 'Supabase is not initialized';
      syncStatusNotifier.value = 'Upload unavailable: Supabase is not initialized';
      return false;
    }

    final failedTables = <String>[];
    _lastUploadFailure = null;
    _legacyTransactionIdsRepaired = 0;
    try {
      final db = await _dbHelper.database;

      for (String table in _tables) {
        try {
          // 1. Fetch all local records
          var localData = await db.query(table);

          if (localData.isNotEmpty) {
            if (table == 'transactions') {
              // Older installs used SQLite AUTOINCREMENT IDs independently,
              // so two offline devices could create different sales with id 1.
              // Preserve the local sale and its items before an upsert can
              // overwrite the other device's cloud row.
              _legacyTransactionIdsRepaired +=
                  await _repairLegacyTransactionIdCollisions(client, db);
              localData = await db.query(table);
            }

            final List<Map<String, dynamic>> dataToSync = [];
            for (var record in localData) {
              final mutableRecord = Map<String, dynamic>.from(record);
              if (table == 'food_items' && mutableRecord['image_path'] != null) {
                final String imgPath = mutableRecord['image_path'];
                // If it's a local file path (not starting with http), upload it first
                if (!imgPath.startsWith('http') && imgPath.isNotEmpty) {
                  final publicUrl = await uploadImage(imgPath);
                  if (publicUrl != null && publicUrl.startsWith('http')) {
                    mutableRecord['image_path'] = publicUrl;
                    // Also update local DB with the public URL
                    await db.update(
                      'food_items',
                      {'image_path': publicUrl},
                      where: 'id = ?',
                      whereArgs: [mutableRecord['id']],
                    );
                  }
                }
              }
              if (table == 'users') {
                mutableRecord.remove('password_hash'); // Do NOT sync password_hash to cloud
                mutableRecord.remove('face_encoding'); // Residual column from older local SQLite schemas
              }
              if (table == 'food_categories') {
                mutableRecord.remove('updated_at');
              }
              if (table == 'transactions') {
                // Retain all transaction fields (order_number, amount_received, change, void_reason, refund_reason)
                // for accurate sales reporting and audit history in the cloud.
              }
              dataToSync.add(mutableRecord);
            }

            // 2. Upsert to Supabase
            // Do not request returned rows: that adds a SELECT policy requirement
            // to an otherwise valid INSERT/UPDATE upsert.
            if (table == 'users') {
              // The cloud users table may require password_hash on INSERT (PostgreSQL NOT NULL),
              // while device-local credential isolation intentionally omits password_hash from cloud payloads.
              // Updating existing users row-by-row updates status/roles without violating NOT NULL.
              for (final userRecord in dataToSync) {
                final id = userRecord['id'];
                if (id != null) {
                  final updatePayload = Map<String, dynamic>.from(userRecord)..remove('id');
                  try {
                    await client.from('users').update(updatePayload).eq('id', id);
                  } catch (_) {
                    await client.from('users').upsert(userRecord);
                  }
                }
              }
            } else {
              await client.from(table).upsert(dataToSync);
            }
          }
        } catch (e) {
          failedTables.add('$table (${_safeErrorCode(e)})');
        }
      }
    } catch (e) {
      _lastUploadFailure = 'local database (${_safeErrorCode(e)})';
      syncStatusNotifier.value = 'Upload failed: $_lastUploadFailure';
      return false;
    }

    if (failedTables.isNotEmpty) {
      _lastUploadFailure = failedTables.join(', ');
      syncStatusNotifier.value = 'Upload incomplete: $_lastUploadFailure';
      return false;
    }
    syncStatusNotifier.value = _legacyTransactionIdsRepaired > 0
        ? 'Upload complete; preserved $_legacyTransactionIdsRepaired conflicting sale(s)'
        : 'Upload complete';
    return true;
  }

  /// Downloads changes from Cloud to Local (For multi-device setups)
  Future<bool> syncFromCloud() async {
    if (backendMode) {
      final backend = BackendSyncService.instance;
      if (backend == null) {
        syncStatusNotifier.value = 'Sync unavailable: backend not configured';
        return false;
      }
      return _enqueue(backend.sync);
    }

    return _enqueue(_syncFromSupabase);
  }

  Future<bool> _syncFromSupabase() async {
    final client = _supabase;
    if (client == null) {
      _lastDownloadFailure = 'Supabase is not initialized';
      syncStatusNotifier.value = 'Download unavailable: Supabase is not initialized';
      return false;
    }

    final failedTables = <String>[];
    _lastDownloadFailure = null;
    try {
      final db = await _dbHelper.database;

      for (String table in _tables) {
        try {
          final cloudData = table == 'users'
              ? await client
                  .from(table)
                  .select('id, full_name, username, role, status, created_at')
              : await client.from(table).select();

          if (cloudData.isNotEmpty) {
            for (var record in cloudData) {
              // Download images to local storage cache in background
              if (table == 'food_items' && record['image_path'] != null) {
                final String pathString = record['image_path'];
                if (pathString.startsWith('http')) {
                  _downloadImageToLocal(pathString);
                }
              }

              // Using REPLACE in SQLite handles upserts while keeping URL in local DB
              if (table == 'transactions') {
                final existing = await db.query(
                  'transactions',
                  where: 'id = ?',
                  whereArgs: [record['id']],
                  limit: 1,
                );
                if (existing.isNotEmpty &&
                    !_sameSaleIdentity(existing.first, record)) {
                  final id = int.tryParse(record['id']?.toString() ?? '');
                  if (id != null) {
                    await db.transaction(
                      (txn) => _rekeyLocalTransaction(txn, id),
                    );
                    _legacyTransactionIdsRepaired++;
                    // The local sale now has a new ID; the cloud sale can be
                    // inserted under its original ID without replacing it.
                  }
                }
                final current = await db.query(
                  'transactions',
                  where: 'id = ?',
                  whereArgs: [record['id']],
                  limit: 1,
                );
                if (current.isNotEmpty) {
                  final localStatus = (current.first['status'] as String? ?? '').trim();
                  final cloudStatus = (record['status'] as String? ?? '').trim();
                  
                  // Sticky terminal states: Local 'Voided', 'Refunded', and 'Served' must never
                  // be reverted to 'Preparing' by a lagged or stale cloud sync pull.
                  final isLocalTerminal = localStatus == 'Voided' || localStatus == 'Refunded' || localStatus == 'Served';
                  if (isLocalTerminal && cloudStatus == 'Preparing') {
                    record['status'] = localStatus;
                  } else if ((localStatus == 'Voided' || localStatus == 'Refunded') && cloudStatus == 'Served') {
                    // Locally voided or refunded orders must remain cancelled
                    record['status'] = localStatus;
                  }
                  
                  record['order_number'] = record['order_number'] ?? current.first['order_number'];
                  record['user_id'] = record['user_id'] ?? current.first['user_id'];
                  record['created_at'] = record['created_at'] ?? current.first['created_at'];
                  record['amount_received'] = record['amount_received'] ?? current.first['amount_received'];
                  record['change'] = record['change'] ?? current.first['change'];
                  record['void_reason'] = record['void_reason'] ?? current.first['void_reason'];
                  record['refund_reason'] = record['refund_reason'] ?? current.first['refund_reason'];
                  await db.update('transactions', record, where: 'id = ?', whereArgs: [record['id']]);
                  continue;
                }
              }
              if (table == 'users') {
                final existing = await db.query('users', where: 'id = ?', whereArgs: [record['id']]);
                final merged = mergePulledUserRecord(
                  record,
                  existing.isEmpty ? null : existing.first,
                );
                record.clear();
                record.addAll(merged);
                if (existing.isNotEmpty) {
                  await db.update('users', record, where: 'id = ?', whereArgs: [record['id']]);
                  continue;
                }
              }
              if (table == 'food_categories') {
                final id = record['id'];
                if (id != null) {
                  final existing = await db.query(
                    'food_categories',
                    where: 'id = ?',
                    whereArgs: [id],
                    limit: 1,
                  );
                  if (existing.isNotEmpty) {
                    await db.update(
                      'food_categories',
                      record,
                      where: 'id = ?',
                      whereArgs: [id],
                    );
                    continue;
                  }
                }
              }
              if (table == 'food_items') {
                final id = record['id'];
                if (id != null) {
                  final existing = await db.query(
                    'food_items',
                    where: 'id = ?',
                    whereArgs: [id],
                    limit: 1,
                  );
                  if (existing.isNotEmpty) {
                    final localUpdated = DateTime.tryParse(existing.first['updated_at']?.toString() ?? '');
                    final cloudUpdated = DateTime.tryParse(record['updated_at']?.toString() ?? '');
                    if (localUpdated != null && cloudUpdated != null && localUpdated.isAfter(cloudUpdated)) {
                      // Local modification is newer than cloud; preserve local edits
                      continue;
                    }
                    await db.update(
                      'food_items',
                      record,
                      where: 'id = ?',
                      whereArgs: [id],
                    );
                    continue;
                  }
                }
              }

              await db.insert(
                table,
                record,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        } catch (e) {
          failedTables.add('$table (${_safeErrorCode(e)})');
        }
      }
    } catch (e) {
      _lastDownloadFailure = 'local database (${_safeErrorCode(e)})';
      syncStatusNotifier.value = 'Download failed: $_lastDownloadFailure';
      return false;
    }

    if (failedTables.isNotEmpty) {
      _lastDownloadFailure = failedTables.join(', ');
      syncStatusNotifier.value = 'Download incomplete: $_lastDownloadFailure';
      return false;
    }
    syncStatusNotifier.value = 'Download complete';
    return true;
  }

  /// Unified 2-way sync: first uploads local changes to cloud, then downloads cloud updates to local
  Future<bool> fullSync() {
    final activeSync = _activeFullSync;
    if (activeSync != null) return activeSync;

    late final Future<bool> trackedSync;
    trackedSync = _enqueue(_performFullSync).whenComplete(() {
      if (identical(_activeFullSync, trackedSync)) _activeFullSync = null;
    });
    _activeFullSync = trackedSync;
    return trackedSync;
  }

  Future<bool> _performFullSync() async {
    if (!isConfigured) {
      syncStatusNotifier.value = 'Sync unavailable: cloud credentials not configured';
      return false;
    }

    syncStatusNotifier.value = 'Syncing with cloud';
    try {
      bool succeeded;
      if (backendMode) {
        // Ubuntu mode is intentionally one-way sales replication. Calling both
        // legacy directions here used to start the same backend upload twice.
        final backend = BackendSyncService.instance;
        if (backend == null) {
          syncStatusNotifier.value = 'Sync unavailable: backend not configured';
          return false;
        }
        succeeded = await backend.sync();
        syncStatusNotifier.value = backend.status.value;
      } else {
        final uploaded = await _syncToSupabase();
        final downloaded = await _syncFromSupabase();
        succeeded = uploaded && downloaded;
        if (succeeded) {
          syncStatusNotifier.value = _legacyTransactionIdsRepaired > 0
              ? 'Cloud sync complete; preserved $_legacyTransactionIdsRepaired conflicting sale(s)'
              : 'Cloud sync complete';
        } else {
          final failures = <String>[];
          if (_lastUploadFailure != null) {
            failures.add('upload: $_lastUploadFailure');
          }
          if (_lastDownloadFailure != null) {
            failures.add('download: $_lastDownloadFailure');
          }
          syncStatusNotifier.value = failures.isEmpty
              ? 'Cloud sync incomplete'
              : 'Cloud sync incomplete (${failures.join('; ')})';
        }
      }

      if (succeeded) onSyncCompletedNotifier.value++;
      return succeeded;
    } catch (e) {
      syncStatusNotifier.value = 'Cloud sync failed (${_safeErrorCode(e)})';
      return false;
    }
  }

  static Future<File?> getCachedImageFile(String pathString) async {
    if (pathString.isEmpty) return null;
    if (!pathString.startsWith('http')) {
      final file = File(pathString);
      return file.existsSync() ? file : null;
    }
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filename = pathString.split('/').last.split('?').first;
      final localPath = path.join(directory.path, 'food_images', filename);
      final file = File(localPath);
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Validates whether an IP address belongs to private, loopback, link-local, or metadata ranges.
  static bool isPrivateOrLoopbackIp(InternetAddress addr) {
    if (addr.isLoopback || addr.isLinkLocal || addr.isMulticast) return true;
    final raw = addr.rawAddress;
    if (addr.type == InternetAddressType.IPv4 && raw.length == 4) {
      if (raw[0] == 10) return true;
      if (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) return true;
      if (raw[0] == 192 && raw[1] == 168) return true;
      if (raw[0] == 127) return true;
      if (raw[0] == 169 && raw[1] == 254) return true;
    } else if (addr.type == InternetAddressType.IPv6 && raw.length == 16) {
      if ((raw[0] & 0xfe) == 0xfc) return true;
    }
    return false;
  }

  /// SSRF Protection: Ensures URL is HTTPS, targets only authorized Supabase hosts,
  /// contains no credentials, and uses only the standard HTTPS port (Gap 18).
  static bool isSafeImageUrl(String url, {String? trustedSupabaseUrl}) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;
    if (uri.scheme.toLowerCase() != 'https') return false;
    if (uri.userInfo.isNotEmpty) return false;
    if (uri.hasPort && uri.port != 443) return false;
    final host = uri.host.toLowerCase();
    if (host.isEmpty) return false;

    final configuredSupabase = trustedSupabaseUrl ??
        (dotenv.isInitialized ? (dotenv.maybeGet('SUPABASE_URL') ?? dotenv.env['SUPABASE_URL']) : null);
    final trustedHost = configuredSupabase != null ? Uri.tryParse(configuredSupabase)?.host.toLowerCase() : null;

    bool isAllowed = false;
    if (trustedHost != null && trustedHost.isNotEmpty && host == trustedHost) {
      isAllowed = true;
    } else if (host == 'supabase.co' || (host.endsWith('.supabase.co') && !host.startsWith('.'))) {
      isAllowed = true;
    }
    return isAllowed;
  }

  Future<String?> _downloadImageToLocal(String url) async {
    try {
      if (!url.startsWith('http')) return url;

      // SSRF validation: scheme, host, credentials, and port
      if (!isSafeImageUrl(url)) {
        return null;
      }

      final uri = Uri.parse(url);

      // SSRF validation: verify DNS does not resolve to loopback/private/metadata IP
      try {
        final addresses = await InternetAddress.lookup(uri.host);
        if (addresses.isEmpty || addresses.any(isPrivateOrLoopbackIp)) {
          return null;
        }
      } catch (_) {
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final filename = url.split('/').last.split('?').first;
      final localPath = path.join(directory.path, 'food_images', filename);

      final file = File(localPath);
      if (await file.exists() && await file.length() > 0) {
        return localPath;
      }

      await Directory(path.dirname(localPath)).create(recursive: true);

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(uri);
      request.followRedirects = true;
      request.maxRedirects = 3;

      final response = await request.close();
      if (response.statusCode == 200) {
        const maxSizeBytes = 5 * 1024 * 1024; // 5 MB
        if (response.contentLength > maxSizeBytes) {
          return null;
        }

        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > maxSizeBytes) {
            return null;
          }
        }

        if (bytes.isNotEmpty) {
          await file.writeAsBytes(bytes);
          return localPath;
        }
      }
    } catch (_) {}
    return null;
  }
}
