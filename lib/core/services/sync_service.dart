import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

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
