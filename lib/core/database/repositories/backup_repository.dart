import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'audit_repository.dart';
import '../database_helper.dart';
import '../../utils/repository_security_guard.dart';
import '../../utils/security_exception.dart';

class BackupRepository {
  final AuditRepository _auditRepo = AuditRepository();

  static const Set<String> _allowedTables = {
    'users',
    'food_categories',
    'food_items',
    'transactions',
    'transaction_items',
    'activity_logs',
    'login_attempts',
    'app_settings',
    'backup_records',
  };

  /// Exports the local database to a MySQL/SQLite-compatible .sql file.
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
      sqlDump.writeln('-- NY Kitchen Database Backup');
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
            // Escape single quotes and backslashes
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
        description: 'Database exported to SQL backup: $backupFileName',
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

  /// Restores the database from a verified .sql or .db backup file.
  /// Requires Administrator authentication (SEC-01 / SEC-03).
  /// Validates file integrity, schema consistency, foreign keys, and rolls back on failure (AT08).
  Future<bool> restoreDatabase(File backupFile) async {
    final admin = await RepositorySecurityGuard.requireAdmin(
      module: 'Backup & Restore',
      action: 'Restore Database',
    );

    if (!await backupFile.exists()) {
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String?,
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Restore Blocked',
        status: 'Blocked',
        description: 'Restore failed: Backup file does not exist.',
      );
      throw const SecurityException('Backup file not found', code: 'INVALID_BACKUP_FILE');
    }

    final fileSize = await backupFile.length();
    if (fileSize == 0) {
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String?,
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Restore Blocked',
        status: 'Blocked',
        description: 'Restore failed: Backup file is empty (0 bytes).',
      );
      throw const SecurityException('Backup file is empty', code: 'INVALID_BACKUP_FILE');
    }

    final filename = basename(backupFile.path).toLowerCase();
    final isSql = filename.endsWith('.sql');
    final isDb = filename.endsWith('.db') || filename.endsWith('.sqlite');

    if (!isSql && !isDb) {
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String?,
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Restore Blocked',
        status: 'Blocked',
        description: 'Restore failed: Unsupported backup file extension ($filename).',
      );
      throw const SecurityException(
        'Only .sql and .db backup files are supported',
        code: 'INVALID_BACKUP_FILE',
      );
    }

    try {
      if (isSql) {
        await _restoreFromSql(backupFile, admin);
      } else {
        await _restoreFromDb(backupFile, admin);
      }

      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String?,
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Database Restored',
        status: 'Success',
        description: 'Database successfully restored from ${basename(backupFile.path)} ($fileSize bytes)',
        deviceInfo: Platform.operatingSystem,
      );
      return true;
    } catch (e) {
      await _auditRepo.logAction(
        userId: admin['id'] as int?,
        username: admin['username'] as String?,
        role: 'admin',
        module: 'Backup & Restore',
        action: 'Restore Failed',
        status: 'Failed',
        description: 'Restore aborted: ${e.toString()}',
        deviceInfo: Platform.operatingSystem,
      );
      rethrow;
    }
  }

  Future<void> _restoreFromSql(File backupFile, Map<String, dynamic> admin) async {
    final lines = await backupFile.readAsLines();
    if (lines.isEmpty) {
      throw const SecurityException('Empty SQL backup content', code: 'INVALID_BACKUP_FILE');
    }

    final statements = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('--') ||
          trimmed.startsWith('/*') ||
          trimmed == 'START TRANSACTION;' ||
          trimmed == 'COMMIT;' ||
          trimmed.startsWith('SET ')) {
        continue;
      }

      if (!trimmed.toUpperCase().startsWith('INSERT INTO')) {
        throw SecurityException(
          'Security policy violation: Unauthorized SQL statement found in backup: $trimmed',
          code: 'UNAUTHORIZED_SQL_STATEMENT',
        );
      }

      // Validate table name
      final match = RegExp(r'^INSERT INTO\s+[`"\[]?([a-zA-Z0-9_]+)[`"\]]?', caseSensitive: false).firstMatch(trimmed);
      if (match == null) {
        throw const SecurityException('Malformed INSERT statement in backup file', code: 'CORRUPTED_BACKUP');
      }
      final tableName = match.group(1)!.toLowerCase();
      if (!_allowedTables.contains(tableName)) {
        throw SecurityException(
          'Security policy violation: Backup contains unauthorized table: $tableName',
          code: 'UNAUTHORIZED_TABLE',
        );
      }

      // Convert MySQL backtick identifiers to SQLite double-quote identifiers
      final sanitizedStatement = trimmed.replaceAll('`', '"');
      statements.add(sanitizedStatement);
    }

    if (statements.isEmpty) {
      throw const SecurityException('No valid data records found in SQL backup', code: 'EMPTY_BACKUP');
    }

    final db = await DatabaseHelper.instance.database;

    // Execute atomic restore transaction with rollback on error (AT08)
    await db.transaction((txn) async {
      // Temporarily disable foreign keys during table wipe and repopulation
      await txn.execute('PRAGMA foreign_keys = OFF');

      // Wipe application tables in reverse dependency order
      const wipeTables = [
        'transaction_items',
        'transactions',
        'food_items',
        'food_categories',
        'login_attempts',
        'app_settings',
        'backup_records',
        'activity_logs',
        'users',
      ];
      for (final table in wipeTables) {
        await txn.delete(table);
      }

      // Execute each insert statement
      for (final sql in statements) {
        await txn.rawInsert(sql);
      }

      // Re-enable and verify foreign keys before committing transaction
      await txn.execute('PRAGMA foreign_keys = ON');
      final fkViolations = await txn.rawQuery('PRAGMA foreign_key_check');
      if (fkViolations.isNotEmpty) {
        throw SecurityException(
          'Foreign key consistency check failed: ${fkViolations.length} orphan records detected',
          code: 'INTEGRITY_VIOLATION',
        );
      }

      final integrity = await txn.rawQuery('PRAGMA integrity_check');
      final integrityResult = integrity.isNotEmpty ? integrity.first.values.first?.toString() : 'unknown';
      if (integrityResult?.toLowerCase() != 'ok') {
        throw SecurityException('SQLite database integrity check failed: $integrityResult', code: 'CORRUPTED_BACKUP');
      }
    });
  }

  Future<void> _restoreFromDb(File backupFile, Map<String, dynamic> admin) async {
    // 1. Verify SQLite binary header magic bytes
    final stream = backupFile.openRead(0, 16);
    final headerBytes = await stream.first;
    if (headerBytes.length < 16) {
      throw const SecurityException('Corrupted backup: File too short for SQLite database', code: 'CORRUPTED_BACKUP');
    }
    final headerStr = String.fromCharCodes(headerBytes.take(15));
    if (!headerStr.startsWith('SQLite format 3')) {
      throw const SecurityException('Invalid SQLite file header', code: 'INVALID_SQLITE_HEADER');
    }

    // 2. Open read-only test verification connection
    final testDb = await openDatabase(backupFile.path, readOnly: true);
    try {
      final integrity = await testDb.rawQuery('PRAGMA integrity_check');
      final integrityResult = integrity.isNotEmpty ? integrity.first.values.first?.toString() : 'unknown';
      if (integrityResult?.toLowerCase() != 'ok') {
        throw SecurityException('Integrity verification failed on backup file: $integrityResult', code: 'CORRUPTED_BACKUP');
      }

      final fkViolations = await testDb.rawQuery('PRAGMA foreign_key_check');
      if (fkViolations.isNotEmpty) {
        throw SecurityException('Foreign key integrity violation in backup: ${fkViolations.length} errors', code: 'INTEGRITY_VIOLATION');
      }

      // Verify core schema tables exist
      final tablesQuery = await testDb.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tablesQuery.map((t) => (t['name'] as String).toLowerCase()).toSet();
      for (final requiredTable in ['users', 'food_items', 'food_categories', 'transactions']) {
        if (!tableNames.contains(requiredTable)) {
          throw SecurityException('Backup missing required core table: $requiredTable', code: 'INCOMPLETE_SCHEMA');
        }
      }
    } finally {
      await testDb.close();
    }

    // 3. Atomic replacement with rollback on error
    final liveDbPath = await DatabaseHelper.getDatabasePath();
    final bakFile = File('$liveDbPath.bak');

    // Create rollback copy of current database
    final liveFile = File(liveDbPath);
    if (await liveFile.exists()) {
      await liveFile.copy(bakFile.path);
    }

    try {
      // Close active database instance
      await DatabaseHelper.closeDatabase();

      // Replace live database with validated backup file
      await backupFile.copy(liveDbPath);

      // Reopen and test live database
      final reopenedDb = await DatabaseHelper.instance.database;
      final liveIntegrity = await reopenedDb.rawQuery('PRAGMA integrity_check');
      if (liveIntegrity.isEmpty || liveIntegrity.first.values.first?.toString().toLowerCase() != 'ok') {
        throw const SecurityException('Live database integrity verification failed after replacement', code: 'RESTORE_VERIFICATION_FAILED');
      }

      // Remove rollback copy on success
      if (await bakFile.exists()) {
        try { await bakFile.delete(); } catch (_) {}
      }
    } catch (e) {
      // Rollback to original database on error
      if (await bakFile.exists()) {
        await DatabaseHelper.closeDatabase();
        await bakFile.copy(liveDbPath);
        await DatabaseHelper.instance.database;
      }
      rethrow;
    }
  }
}
