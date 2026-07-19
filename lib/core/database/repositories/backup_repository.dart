import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'audit_repository.dart';

class BackupRepository {
  final AuditRepository _auditRepo = AuditRepository();

  Future<String?> exportDatabase() async {
    try {
      final dbPath = join(await getDatabasesPath(), 'ny_kitchen.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return null;
      }

      // Try to get Downloads directory, fallback to Documents
      Directory? exportDir;
      try {
        exportDir = await getDownloadsDirectory();
      } catch (_) {}
      
      exportDir ??= await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final backupFileName = 'ny_kitchen_backup_$timestamp.db';
      final backupPath = join(exportDir.path, backupFileName);

      await dbFile.copy(backupPath);
      
      // Log the action
      await _auditRepo.logAction(
        userId: 1, // Using 1 (Admin) as placeholder
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Exported Database to $backupPath',
        status: 'Success',
        deviceInfo: Platform.operatingSystem,
      );

      return backupPath;
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
