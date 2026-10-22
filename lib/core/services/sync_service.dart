// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'backend_sync_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SyncService {
  // Selected once at startup. A failed backend setup must not fall back to cloud.
  static bool backendMode = false;
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
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

  /// Starts an automatic periodic sync from the cloud to keep local data fresh
  void startAutomaticSync({int intervalSeconds = 10}) {
    _syncTimer?.cancel();
    // Run immediately first
    syncFromCloud();
    // Then repeat periodically
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      syncFromCloud();
    });
  }

  void stopAutomaticSync() {
    _syncTimer?.cancel();
  }

  /// Strips sensitive credentials (password_hash and biometric face_encoding) before syncing to cloud.
  static Map<String, dynamic> sanitizeUserForCloudSync(Map<String, dynamic> record) {
    final sanitized = Map<String, dynamic>.from(record);
    sanitized.remove('password_hash');
    sanitized.remove('face_encoding');
    return sanitized;
  }

  /// Merges pulled cloud user record with existing local record, preserving local biometric face_encoding, password_hash, and lockout counters.
  static Map<String, dynamic> mergePulledUserRecord(
    Map<String, dynamic> cloudRecord,
    Map<String, dynamic>? existingLocal,
  ) {
    final merged = Map<String, dynamic>.from(cloudRecord);
    if (existingLocal != null) {
      merged['face_encoding'] = existingLocal['face_encoding'];
      merged['failed_login_count'] = merged['failed_login_count'] ?? existingLocal['failed_login_count'];
      merged['password_hash'] = merged['password_hash'] ?? existingLocal['password_hash'];
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
    } catch (e) {
      print('Image upload failed: $e');
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

  /// Runs a full background sync from SQLite (Primary) to Supabase (Backup)
  Future<void> syncToCloud() async {
    if (backendMode) {
      // Checkout has already committed locally; never await network on this path.
      unawaited(BackendSyncService.instance?.sync() ?? Future<void>.value());
      return;
    }
    try {
      final db = await _dbHelper.database;

      for (String table in _tables) {
        try {
          // 1. Fetch all local records
          final List<Map<String, dynamic>> localData = await db.query(table);

          if (localData.isNotEmpty) {
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
                mutableRecord.remove('face_encoding'); // Do NOT sync face_encoding to cloud (biometrics remain local)
              }
              if (table == 'food_categories') {
                mutableRecord.remove('updated_at');
              }
              if (table == 'transactions') {
                // Keep order_number so it syncs to cloud
                // mutableRecord.remove('order_number');
                mutableRecord.remove('amount_received');
                mutableRecord.remove('change');
                mutableRecord.remove('void_reason');
                mutableRecord.remove('refund_reason');
              }
              dataToSync.add(mutableRecord);
            }

            // 2. Upsert to Supabase
            await _supabase?.from(table).upsert(dataToSync).select();

            print('Synced ${dataToSync.length} records to $table.');
          }
        } catch (e) {
          print('SyncToCloud failed for table $table: $e');
        }
      }

      print('Cloud Backup Sync Complete!');
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  /// Downloads changes from Cloud to Local (For multi-device setups)
  Future<void> syncFromCloud() async {
    if (backendMode) {
      await BackendSyncService.instance?.sync();
      return;
    }
    try {
      final db = await _dbHelper.database;

      for (String table in _tables) {
        try {
          final cloudData = await _supabase?.from(table).select();

          if (cloudData != null && cloudData.isNotEmpty) {
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
                final existing = await db.query('transactions', where: 'id = ?', whereArgs: [record['id']]);
                if (existing.isNotEmpty) {
                  // If local transaction is "Served" but cloud is "Preparing", don't overwrite with older cloud status!
                  final localStatus = existing.first['status'] as String;
                  final cloudStatus = record['status'] as String;
                  
                  // Only allow cloud to overwrite if cloud is moving forward or local is same.
                  if (localStatus == 'Served' && cloudStatus == 'Preparing') {
                     record['status'] = 'Served'; // Preserve local served status
                  }
                  
                  record['order_number'] = record['order_number'] ?? existing.first['order_number'];
                  record['amount_received'] = record['amount_received'] ?? existing.first['amount_received'];
                  record['change'] = record['change'] ?? existing.first['change'];
                  record['void_reason'] = record['void_reason'] ?? existing.first['void_reason'];
                  record['refund_reason'] = record['refund_reason'] ?? existing.first['refund_reason'];
                }
              }
              if (table == 'users') {
                final existing = await db.query('users', where: 'id = ?', whereArgs: [record['id']]);
                if (existing.isNotEmpty) {
                  final merged = mergePulledUserRecord(record, existing.first);
                  record.clear();
                  record.addAll(merged);
                }
              }

              await db.insert(
                table,
                record,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
            print(
              'Synced ${cloudData.length} records from cloud to local $table.',
            );
          }
        } catch (e) {
          print('SyncFromCloud failed for table $table: $e');
        }
      }
    } catch (e) {
      print('Download sync failed: $e');
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
