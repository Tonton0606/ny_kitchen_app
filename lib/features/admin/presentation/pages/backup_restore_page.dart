import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/database/repositories/backup_repository.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  final BackupRepository _backupRepo = BackupRepository();
  bool _isExporting = false;
  String? _lastBackupPath;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    
    final file = await _backupRepo.exportDatabase();
    
    if (mounted) {
      setState(() {
        _isExporting = false;
        if (file != null) {
          _lastBackupPath = file.path;
        }
      });

      if (file != null) {
        // Trigger the cross-platform native share dialog
        await Share.shareXFiles(
          [XFile(file.path)], 
          text: 'NY Kitchen MySQL Database Backup'
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to backup database.', style: TextStyle(color: Colors.white)),
            backgroundColor: AppColors.brandRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Backup & Restore',
              style: AppTypography.pageTitle,
            ),
            const SizedBox(height: 4),
            const Text(
              'Securely export your local SQLite database for safekeeping. You can use these backups to restore the system in case of data loss.',
              style: AppTypography.pageSubtitle,
            ),
            const SizedBox(height: 32),
            
            // Export Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.download_rounded, color: AppColors.goldenYellow, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Export Database',
                        style: AppTypography.sectionTitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Creates a complete snapshot of all transactions, food items, users, and audit logs. The file will be saved directly to your Downloads or Documents folder.',
                    style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 24),
                  if (_lastBackupPath != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last Backup Location:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SelectableText(
                                  _lastBackupPath!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    color: AppColors.darkCharcoal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _isExporting ? null : _handleExport,
                      icon: _isExporting 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Icon(Icons.backup_rounded),
                      label: Text(
                        _isExporting ? 'Exporting...' : 'Create Backup Now',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.goldenYellow,
                        foregroundColor: AppColors.darkCharcoal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Import Section (Placeholder for now)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.upload_rounded, color: AppColors.tertiary, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Restore Database',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Restore the system from a previous backup file (.db). WARNING: This will overwrite all current data in the system and cannot be undone.',
                    style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: null, // Disabled for Phase 3, pending Phase 4 security
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text(
                        'Restore from File (Coming Soon)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.tertiary,
                        side: const BorderSide(color: AppColors.tertiary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
