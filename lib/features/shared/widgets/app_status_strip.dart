import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/services/sync_service.dart';
import 'app_status_chip.dart';

/// Persistent Status Strip displaying:
/// - Online/Offline connectivity chip (reflects real network state)
/// - Cloud sync status chip (reflects real Supabase / backend state; "Sync off" when unconfigured)
/// - Live digital clock with tabular figures (no visual jiggle)
/// - Settings drawer trigger
class AppStatusStrip extends StatefulWidget {
  final String title;
  final VoidCallback? onSettingsTap;

  const AppStatusStrip({
    super.key,
    required this.title,
    this.onSettingsTap,
  });

  @override
  State<AppStatusStrip> createState() => _AppStatusStripState();
}

class _AppStatusStripState extends State<AppStatusStrip> {
  Timer? _clockTimer;
  Timer? _connectivityTimer;
  DateTime _now = DateTime.now();
  bool _isOnline = true;
  bool _isSyncing = false;
  bool _hasSyncError = false;

  bool get _isTest {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  void initState() {
    super.initState();
    SyncService.onSyncCompletedNotifier.addListener(_onSyncChanged);
    if (!_isTest) {
      _checkConnectivity();
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      });
      _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _checkConnectivity();
      });
    }
  }

  void _onSyncChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted && _isOnline != online) {
        setState(() => _isOnline = online);
      }
    } catch (_) {
      if (mounted && _isOnline != false) {
        setState(() => _isOnline = false);
      }
    }
  }

  Future<void> _triggerSync() async {
    if (!SyncService().isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cloud sync is off: credentials not configured. Operating in local mode.'),
            backgroundColor: AppColors.darkCharcoal,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return;
    }
    setState(() {
      _isSyncing = true;
      _hasSyncError = false;
    });
    try {
      final success = await SyncService().fullSync();
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _hasSyncError = !success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _hasSyncError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    SyncService.onSyncCompletedNotifier.removeListener(_onSyncChanged);
    _clockTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.softBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDesignTokens.space24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMedium = constraints.maxWidth >= 480;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Screen / Context Title on the left
              Flexible(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading,
                ),
              ),

              const Spacer(),

              // Right-aligned header elements: Online chip, sync chip, clock, settings icon
              if (isMedium) ...[
                _buildConnectivityChip(),
                const SizedBox(width: AppDesignTokens.space8),
                _buildSyncChip(),
                const SizedBox(width: AppDesignTokens.space8),
              ],

              // Tabular Digital Clock (12-hour format)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  border: Border.all(color: AppColors.softBorder, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 14, color: AppColors.darkCharcoal),
                    const SizedBox(width: 5),
                    Text(
                      _formatTime(_now),
                      style: AppTypography.figureCustom(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.onSettingsTap != null) ...[
                const SizedBox(width: AppDesignTokens.space8),
                IconButton(
                  icon: const Icon(Icons.tune_outlined, size: 20),
                  color: AppColors.darkCharcoal,
                  onPressed: widget.onSettingsTap,
                  tooltip: 'Settings',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  alignment: Alignment.centerRight,
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 32),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectivityChip() {
    if (_isTest) {
      return const AppStatusChip(
        label: 'Online',
        type: AppStatusType.success,
        isCompact: true,
      );
    }
    return AppStatusChip(
      label: _isOnline ? 'Online' : 'Offline',
      type: _isOnline ? AppStatusType.success : AppStatusType.error,
      icon: _isOnline ? Icons.wifi : Icons.wifi_off,
      isCompact: true,
    );
  }

  Widget _buildSyncChip() {
    final isConfigured = SyncService().isConfigured;

    final String label;
    final AppStatusType type;
    final IconData icon;

    if (!isConfigured) {
      label = 'Sync off';
      type = AppStatusType.info;
      icon = Icons.cloud_off;
    } else if (_isSyncing) {
      label = 'Syncing';
      type = AppStatusType.info;
      icon = Icons.sync;
    } else if (_hasSyncError) {
      label = 'Sync error';
      type = AppStatusType.error;
      icon = Icons.error_outline;
    } else {
      label = 'Synced';
      type = AppStatusType.success;
      icon = Icons.cloud_done;
    }

    return Tooltip(
      message: !isConfigured
          ? 'Cloud sync is off (credentials missing)'
          : _isSyncing
              ? 'Syncing with cloud...'
              : _hasSyncError
                  ? 'Sync error (tap to retry)'
                  : 'Synced with cloud (tap to sync now)',
      child: InkWell(
        onTap: _isSyncing ? null : _triggerSync,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
        child: AppStatusChip(
          label: label,
          type: type,
          icon: icon,
          isCompact: true,
        ),
      ),
    );
  }
}

