import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'audit_repository.dart';
import '../database_helper.dart';

class BackupRepository {
  final AuditRepository _auditRepo = AuditRepository();

  /// Exports the local database to a MySQL-compatible .sql file.
  Future<File?> exportDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // We will export all tables except sqlite_sequence
      final tablesQuery = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
      final tables = tablesQuery.map((t) => t['name'] as String).toList();
      
      StringBuffer sqlDump = StringBuffer();
      sqlDump.writeln('-- NY Kitchen MySQL Database Backup');
      sqlDump.writeln('-- Generated at ${DateTime.now().toIso8601String()}');
      sqlDump.writeln('SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";');
      sqlDump.writeln('START TRANSACTION;');
      sqlDump.writeln('SET time_zone = "+00:00";\n');

      for (var table in tables) {
        final rows = await db.query(table);
        if (rows.isEmpty) continue;
        
        sqlDump.writeln('-- --------------------------------------------------------');
        sqlDump.writeln('-- Table structure and data for table `$table`');
        sqlDump.writeln('-- --------------------------------------------------------\n');
        
        for (var row in rows) {
          final columns = row.keys.map((k) => '`$k`').join(', ');
          final values = row.values.map((v) {
            if (v == null) return 'NULL';
            if (v is num) return v.toString();
            // Escape single quotes and backslashes for MySQL
            String strVal = v.toString().replaceAll('\\', '\\\\').replaceAll("'", "''");
            return "'$strVal'";
          }).join(', ');
          
          sqlDump.writeln('INSERT INTO `$table` ($columns) VALUES ($values);');
        }
        sqlDump.writeln('');
      }
      
      sqlDump.writeln('COMMIT;');
      
      // Save to a temporary directory so we can share it
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupFileName = 'ny_kitchen_backup_$timestamp.sql';
      final backupFile = File(join(tempDir.path, backupFileName));
      
      await backupFile.writeAsString(sqlDump.toString());
      
      // Log the action
      await _auditRepo.logAction(
        userId: 1, // Using 1 (Admin) as placeholder
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Exported MySQL Database to ${backupFile.path}',
        status: 'Success',
        deviceInfo: Platform.operatingSystem,
      );

      return backupFile;
    } catch (e) {
      await _auditRepo.logAction(
        userId: 1,
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Failed to export database: ${e.toString()}',
        status: 'Failed',
        deviceInfo: Platform.operatingSystem,
      );
      return null;
    }
  }
}
