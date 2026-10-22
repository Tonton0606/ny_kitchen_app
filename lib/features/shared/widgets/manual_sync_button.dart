import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/services/sync_service.dart';

/// Interactive manual Cloud Sync button with spinning loading animation and status feedback.
/// Supports both wide/compact layouts (e.g. icon + text or compact icon pill).
class ManualSyncButton extends StatefulWidget {
  final bool isCompact;
  final VoidCallback? onSyncCompleted;

  const ManualSyncButton({
    super.key,
    this.isCompact = false,
    this.onSyncCompleted,
  });

  @override
  State<ManualSyncButton> createState() => _ManualSyncButtonState();
}

class _ManualSyncButtonState extends State<ManualSyncButton>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  bool _hasSyncError = false;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _performSync() async {
    if (!SyncService().isConfigured) {
      final status = SyncService.syncStatusNotifier.value;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$status. Operating in local mode.'),
              ),
            ],
          ),
          backgroundColor: AppColors.darkCharcoal,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _hasSyncError = false;
    });
    _rotationController.repeat();

    try {
      final success = await SyncService().fullSync();

      if (!mounted) return;

      if (success) {
        setState(() => _hasSyncError = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Cloud Sync completed successfully!'),
              ],
            ),
            backgroundColor: AppColors.forest,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        widget.onSyncCompleted?.call();
      } else {
        setState(() => _hasSyncError = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    SyncService.syncStatusNotifier.value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.goldInk,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasSyncError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          backgroundColor: AppColors.brandRed,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) {
        _rotationController.stop();
        _rotationController.reset();
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        SyncService.syncModeNotifier,
        SyncService.syncStatusNotifier,
      ]),
      builder: (context, child) {
        final mode = SyncService.syncModeNotifier.value;
        final syncStatus = SyncService.syncStatusNotifier.value;
        if (mode != 'manual') {
          return const SizedBox.shrink();
        }

        final isConfigured = SyncService().isConfigured;
        final hasSyncError = _hasSyncError ||
            syncStatus.contains('incomplete') ||
            syncStatus.startsWith('Sync unavailable') ||
            syncStatus.startsWith('Sync failed') ||
            syncStatus.startsWith('Upload failed') ||
            syncStatus.startsWith('Download failed');

        final String label;
        final String tooltip;
        final IconData icon;
        final Color iconColor;

        if (!isConfigured) {
          label = 'Sync off';
          tooltip = '$syncStatus; operating in local mode';
          icon = LucideIcons.cloud_off;
          iconColor = AppColors.mutedBrown;
        } else if (_isSyncing || syncStatus == 'Syncing with cloud') {
          label = 'Syncing';
          tooltip = 'Syncing with cloud...';
          icon = LucideIcons.refresh_cw;
          iconColor = AppColors.inkBlue;
        } else if (hasSyncError) {
          label = 'Sync error';
          tooltip = '$syncStatus (tap to retry)';
          icon = LucideIcons.circle_alert;
          iconColor = AppColors.brandRed;
        } else if (syncStatus == 'Not synchronized') {
          label = 'Sync now';
          tooltip = 'Tap to sync with cloud';
          icon = LucideIcons.cloud;
          iconColor = AppColors.inkBlue;
        } else {
          label = 'Synced';
          tooltip = 'Synced with cloud (tap to sync now)';
          icon = LucideIcons.cloud;
          iconColor = AppColors.inkBlue;
        }

        if (widget.isCompact) {
          return Tooltip(
            message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _isSyncing ? null : _performSync,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.creamBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.softBorder, width: 1),
              ),
              child: _isSyncing
                  ? RotationTransition(
                      turns: _rotationController,
                      child: Icon(
                        icon,
                        size: 16,
                        color: iconColor,
                      ),
                    )
                  : Icon(
                      icon,
                      size: 16,
                      color: iconColor,
                    ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          onTap: _isSyncing ? null : _performSync,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.creamBackground,
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              border: Border.all(color: AppColors.softBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isSyncing)
                  RotationTransition(
                    turns: _rotationController,
                    child: Icon(
                      icon,
                      size: 15,
                      color: iconColor,
                    ),
                  )
                else
                  Icon(
                    icon,
                    size: 15,
                    color: iconColor,
                  ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.buttonSmall.copyWith(
                    color: hasSyncError ? AppColors.brandRed : AppColors.darkCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}
