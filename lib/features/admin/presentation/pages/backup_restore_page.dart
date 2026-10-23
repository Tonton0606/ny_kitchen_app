import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../../core/database/repositories/backup_repository.dart';
import '../../../../../core/utils/security_exception.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_buttons.dart';
import '../../../shared/widgets/app_confirm_dialog.dart';
import '../../../shared/widgets/app_status_chip.dart';

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({super.key});

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  final BackupRepository _backupRepo = BackupRepository();
  bool _isExporting = false;
  bool _isRestoring = false;
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
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)], 
          text: 'NY Kitchen MySQL Database Backup',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to backup database.', style: AppTypography.body),
            backgroundColor: AppColors.brandRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Database backups',
      extensions: <String>['sql', 'db'],
    );
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file == null) return;

    if (!mounted) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Restore Database',
      consequenceText:
          'Restoring will overwrite current local database records with the contents of ${file.name}. Ensure you have exported a recent backup if you need to keep current changes.',
      confirmText: 'Restore Database',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isRestoring = true);

    try {
      await _backupRepo.restoreDatabase(File(file.path));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Database successfully restored.',
            style: AppTypography.body,
          ),
          backgroundColor: AppColors.forest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is SecurityException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restore failed: $msg',
            style: AppTypography.body,
          ),
          backgroundColor: AppColors.brandRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Export Section Card
            AppCard(
              padding: const EdgeInsets.all(AppDesignTokens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDesignTokens.space8),
                        decoration: BoxDecoration(
                          color: AppColors.goldTint,
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: AppColors.darkCharcoal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.space12),
                      const Text(
                        'Export Database',
                        style: AppTypography.headingLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.space12),
                  const Text(
                    'Creates a complete snapshot of all transactions, food items, users, and audit logs. The file will be saved directly to your Downloads or Documents folder.',
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: AppDesignTokens.space24),
                  if (_lastBackupPath != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppDesignTokens.space12),
                      decoration: BoxDecoration(
                        color: AppColors.creamBackground,
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        border: Border.all(color: AppColors.softBorder),
                      ),
                      child: Row(
                        children: [
                          const AppStatusChip(
                            label: 'BACKUP READY',
                            type: AppStatusType.success,
                            icon: Icons.check_circle_outline,
                            isCompact: true,
                          ),
                          const SizedBox(width: AppDesignTokens.space12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Last Backup File Path:',
                                  style: AppTypography.label,
                                ),
                                const SizedBox(height: 2),
                                SelectableText(
                                  _lastBackupPath!,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.space24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      text: _isExporting ? 'Exporting...' : 'Create Backup Now',
                      icon: Icons.backup_rounded,
                      isLoading: _isExporting,
                      onPressed: _isExporting ? null : _handleExport,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDesignTokens.space24),

            // Restore Section Card
            AppCard(
              padding: const EdgeInsets.all(AppDesignTokens.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDesignTokens.space8),
                        decoration: BoxDecoration(
                          color: AppColors.creamBackground,
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        ),
                        child: const Icon(
                          Icons.upload_rounded,
                          color: AppColors.darkCharcoal,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppDesignTokens.space12),
                      const Text(
                        'Restore Database',
                        style: AppTypography.headingLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesignTokens.space12),
                  const Text(
                    'Restore the system from a previous backup file (.db). This operation restores previous state, replaces the local database, and triggers replication.',
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: AppDesignTokens.space16),
                  Container(
                    padding: const EdgeInsets.all(AppDesignTokens.space12),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                      border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.brandRed,
                          size: 18,
                        ),
                        SizedBox(width: AppDesignTokens.space8),
                        Expanded(
                          child: Text(
                            'Warning: Restoring will overwrite existing local data with the selected backup file (.sql or .db). State will be replaced atomically.',
                            style: AppTypography.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDesignTokens.space24),
                  SizedBox(
                    width: double.infinity,
                    child: AppSecondaryButton(
                      text: _isRestoring ? 'Restoring Database...' : 'Restore Database from File',
                      icon: Icons.restore_rounded,
                      onPressed: (_isRestoring || _isExporting) ? null : _handleRestore,
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

