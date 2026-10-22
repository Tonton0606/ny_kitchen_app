import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/session/session_manager.dart';
import 'app_status_chip.dart';
import 'manual_sync_button.dart';

/// Persistent Status Strip displaying:
/// - Online/Offline connectivity chip (reflects real network state)
/// - Cloud sync status chip (reflects real Supabase / backend state; "Sync off" when unconfigured)
/// - Live digital clock with tabular figures (no visual jiggle)
/// - Pinned role & shift identifier
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

  bool get _isTest {
    if (Platform.environment.containsKey('FLUTTER_TEST')) return true;
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _clockTimer?.cancel();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final role = (user?['role'] as String?)?.toUpperCase() ?? 'POS';
    final name = (user?['full_name'] as String?) ?? 'User';

    return Container(
      width: double.infinity,
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.softBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final isMedium = constraints.maxWidth >= 480;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Screen / Context Title
              Flexible(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Pinned Role Badge (Wide screens only)
              if (isWide) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.darkCharcoal,
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.goldenYellow,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$role • $name',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],

              const Spacer(),

              // Online / Connectivity Chip (Medium + Wide)
              if (isMedium) ...[
                _buildConnectivityChip(),
                const SizedBox(width: 8),
              ],

              // Interactive Manual Cloud Sync Button (Wide screens only)
              if (isWide) ...[
                const ManualSyncButton(isCompact: false),
                const SizedBox(width: 12),
              ],

              // Tabular Digital Clock
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
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.onSettingsTap != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.tune_outlined, size: 20),
                  color: AppColors.darkCharcoal,
                  onPressed: widget.onSettingsTap,
                  tooltip: 'Settings',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
}

