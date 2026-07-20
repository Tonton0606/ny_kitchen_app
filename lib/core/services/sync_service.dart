import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

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
    'login_attempts'
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
      if (!await file.exists()) return localPath; // Return as-is if it's not a local file we can find

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(localPath)}';
      final String fullPath = await _supabase.storage
          .from('food_images')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
          
      return _supabase.storage.from('food_images').getPublicUrl(fileName);
    } catch (e) {
      print('Image upload failed: $e');
      return localPath; // fallback to local path if upload fails
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
          // 2. Upsert to Supabase
          // Upsert matches by primary key (id) and updates existing records,
          // or inserts new ones.
          await _supabase
              .from(table)
              .upsert(localData)
              .select();
              
          print('Synced ${localData.length} records to $table.');
        }
      }
      
      print('Cloud Backup Sync Complete!');
    } catch (e) {
      print('Sync failed: $e');
      // Here you could log the failure to a local error log table if needed.
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
            // Using REPLACE in SQLite handles upserts
            await db.insert(
              table, 
              record, 
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          print('Synced ${cloudData.length} records from cloud to local $table.');
        }
      }
    } catch (e) {
      print('Download sync failed: $e');
    }
  }
}
