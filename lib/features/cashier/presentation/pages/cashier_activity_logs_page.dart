import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/repositories/audit_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';

class CashierActivityLogsPage extends StatefulWidget {
  const CashierActivityLogsPage({super.key});

  @override
  State<CashierActivityLogsPage> createState() => _CashierActivityLogsPageState();
}

class _CashierActivityLogsPageState extends State<CashierActivityLogsPage> {
  final AuditRepository _auditRepo = AuditRepository();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final user = SessionManager().currentUser;
    final userId = user?['id'] as int?;

    final logs = await _auditRepo.getLogs(
      userId: userId,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
    );
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged() {
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Activity Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkCharcoal,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.softBorder, height: 1.0),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkCharcoal),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.goldenYellow,
                                  onPrimary: AppColors.darkCharcoal,
                                  surface: Colors.white,
                                  onSurface: AppColors.darkCharcoal,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                          _onFilterChanged();
                        }
                      },
                      icon: const Icon(Icons.date_range, size: 18, color: AppColors.darkCharcoal),
                      label: Text(
                        _selectedDateRange != null 
                            ? '${DateFormat('MM/dd/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MM/dd/yyyy').format(_selectedDateRange!.end)}'
                            : 'Filter Date',
                        style: const TextStyle(color: AppColors.darkCharcoal, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.softBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    if (_selectedDateRange != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.brandRed),
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                          _onFilterChanged();
                        },
                        tooltip: 'Clear Date Filter',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(child: Text('No activity logs found.', style: TextStyle(color: AppColors.mutedText)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: _logs.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.softBorder),
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          final action = log['action'] ?? '';
                          final module = log['module'] ?? '';
                          final status = log['status'] as String? ?? 'Unknown';
                          final isSuccess = status == 'Success';
                          final dateStr = log['created_at'] ?? '';
                          String formattedDate = '';
                          if (dateStr.isNotEmpty) {
                            final parsedDate = DateTime.tryParse(dateStr);
                            if (parsedDate != null) {
                              formattedDate = '${parsedDate.month}/${parsedDate.day}/${parsedDate.year} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: isSuccess ? AppColors.success.withValues(alpha: 0.1) : AppColors.brandRed.withValues(alpha: 0.1),
                                  radius: 20,
                                  child: Icon(
                                    isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                                    color: isSuccess ? AppColors.success : AppColors.brandRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        action,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.darkCharcoal),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Module: $module',
                                        style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
