import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'audit_repository.dart';
import '../database_helper.dart';
import '../../utils/repository_security_guard.dart';

class BackupRepository {
  final AuditRepository _auditRepo = AuditRepository();

  /// Exports the local database to a MySQL-compatible .sql file.
  Future<File?> exportDatabase() async {
    // SEC-01 & SEC-03: Enforce administrator authorization
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Backup & Restore',
      action: 'Export Database',
    );

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
      
      // Log the action using authoritative session identity (SEC-01 / SEC-03)
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String? ?? 'Admin',
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Database Backup Exported',
        status: 'Success',
        description: 'Database exported to MySQL compatible SQL file: $backupFileName',
        deviceInfo: Platform.operatingSystem,
      );

      return backupFile;
    } catch (e) {
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String? ?? 'Admin',
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Export Failed',
        status: 'Failed',
        description: 'Failed to export database: ${e.toString()}',
        deviceInfo: Platform.operatingSystem,
      );
      return null;
    }
  }
}
