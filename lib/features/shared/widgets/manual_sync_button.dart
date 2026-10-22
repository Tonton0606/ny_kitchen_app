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
    if (_isSyncing) return;

    setState(() => _isSyncing = true);
    _rotationController.repeat();

    try {
      final success = await SyncService().fullSync();

      if (!mounted) return;

      if (success) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Cloud Sync completed with warnings (offline/check network)'),
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
    if (widget.isCompact) {
      return Tooltip(
        message: _isSyncing ? 'Syncing with cloud...' : 'Sync with Cloud (2-Way)',
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
                      child: const Icon(
                        LucideIcons.refresh_cw,
                        size: 16,
                        color: AppColors.inkBlue,
                      ),
                    )
                  : const Icon(
                      LucideIcons.cloud,
                      size: 16,
                      color: AppColors.darkCharcoal,
                    ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: _isSyncing ? 'Syncing with cloud...' : 'Sync with Cloud (2-Way)',
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
                    child: const Icon(
                      LucideIcons.refresh_cw,
                      size: 15,
                      color: AppColors.inkBlue,
                    ),
                  )
                else
                  const Icon(
                    LucideIcons.cloud,
                    size: 15,
                    color: AppColors.inkBlue,
                  ),
                const SizedBox(width: 6),
                Text(
                  _isSyncing ? 'Syncing...' : 'Cloud Sync',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
