import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SyncService {
  final SupabaseClient _supabase = Supabase.instance.client;
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

  /// Uploads a local image file to Supabase Storage and returns the public URL
  Future<String?> uploadImage(String localPath) async {
    try {
      if (localPath.startsWith('http')) return localPath; // Already a URL
      if (localPath.isEmpty) return null;

      final file = File(localPath);
      if (!await file.exists())
        return localPath; // Return as-is if it's not a local file we can find

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}';
      final storagePath = await _supabase.storage
          .from('food_images')
          .upload(
            fileName,
            file,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _contentTypeFor(localPath),
            ),
          );

      return _supabase.storage.from('food_images').getPublicUrl(storagePath);
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
    try {
      final db = await _dbHelper.database;

      for (String table in _tables) {
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
            dataToSync.add(mutableRecord);
          }

          // 2. Upsert to Supabase
          await _supabase.from(table).upsert(dataToSync).select();

          print('Synced ${dataToSync.length} records to $table.');
        }
      }

      print('Cloud Backup Sync Complete!');
    } catch (e) {
      print('Sync failed: $e');
    }
  }

  /// Downloads changes from Cloud to Local (For multi-device setups)
  Future<void> syncFromCloud() async {
    try {
      final db = await _dbHelper.database;

      for (String table in _tables) {
        final cloudData = await _supabase.from(table).select();

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

  Future<String?> _downloadImageToLocal(String url) async {
    try {
      if (!url.startsWith('http')) return url;

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

      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 5;

      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (acc, data) => acc..addAll(data));
        if (bytes.isNotEmpty) {
          await file.writeAsBytes(bytes);
          print('Cached image locally: $localPath');
          return localPath;
        }
      }
    } catch (e) {
      print('Failed to download image $url: $e');
    }
    return null;
  }
}
