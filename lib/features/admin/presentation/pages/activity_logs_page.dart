import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
import '../../../../../core/services/export_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  final AuditRepository _auditRepo = AuditRepository();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _roleFilter = 'All';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await _auditRepo.getLogs(
      role: _roleFilter,
      startDate: _selectedDateRange?.start,
      endDate: _selectedDateRange?.end,
      search: _searchQuery,
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
    // Filters are now handled in the repository, so we just use _logs
    final filteredLogs = _logs;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Logs',
                      style: AppTypography.pageTitle,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'System-wide security and audit trail records',
                      style: AppTypography.pageSubtitle,
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_isLoading) return;
                        if (filteredLogs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No logs to print')),
                          );
                          return;
                        }
                        ExportService.printLogsPDF(filteredLogs);
                      },
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Print'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkCharcoal,
                        side: const BorderSide(color: AppColors.softBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      onSelected: (value) {
                        if (_isLoading) return;
                        if (filteredLogs.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No logs to export')),
                          );
                          return;
                        }
                        if (value == 'excel') {
                          ExportService.exportLogsToExcel(filteredLogs, context);
                        } else if (value == 'pdf') {
                          ExportService.exportLogsToPDF(filteredLogs, context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'excel',
                          child: Text('Export as Excel (.xlsx)'),
                        ),
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Text('Export as PDF (.pdf)'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.download, size: 18, color: Colors.black),
                            SizedBox(width: 8),
                            Text('Export', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: 360,
                    child: TextField(
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                        _onFilterChanged();
                      },
                      decoration: InputDecoration(
                        hintText: 'Search users, actions, or modules...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  value: _roleFilter,
                  icon: Icons.person_outline,
                  items: const ['All', 'admin', 'cashier', 'None'],
                  onChanged: (val) {
                    setState(() => _roleFilter = val!);
                    _onFilterChanged();
                  },
                ),
                const SizedBox(width: 12),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            headingRowHeight: 48,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 52,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Timestamp',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'User',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Role',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Module',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Device',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'IP Address',
                        style: AppTypography.tableHeader,
                      ),
                    ),
                  ],
                  rows: filteredLogs.map((log) {
                    final status = log['status'] as String? ?? 'Unknown';
                    final isSuccess = status == 'Success';
                    final isFailed = status == 'Failed';
                    Color statusColor;
                    if (isSuccess) {
                      statusColor = AppColors.success;
                    } else if (isFailed) {
                      statusColor = AppColors.brandRed;
                    } else {
                      statusColor = AppColors.tertiary;
                    }
                    
                    final dateStr = log['created_at'] ?? '';
                    String formattedDate = '';
                    if (dateStr.isNotEmpty) {
                      final parsedDate = DateTime.tryParse(dateStr);
                      if (parsedDate != null) {
                        formattedDate = '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
                      }
                    }

                    final role = log['role'] as String? ?? '';
                    final roleDisplay = role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : '';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            formattedDate,
                            style: AppTypography.tableCellSecondary,
                          ),
                        ),
                        DataCell(
                          Text(
                            log['username'] ?? 'System',
                            style: AppTypography.tableCellPrimary,
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleDisplay == 'Admin'
                                  ? AppColors.tertiary.withValues(alpha: 0.12)
                                  : (roleDisplay == 'Cashier'
                                        ? AppColors.goldenYellow
                                        : AppColors.mutedText.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleDisplay,
                              style: TextStyle(
                                color: roleDisplay == 'Admin'
                                    ? AppColors.tertiary
                                    : (roleDisplay == 'Cashier'
                                          ? AppColors.darkCharcoal
                                          : AppColors.mutedText),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              log['module'] ?? '',
                              style: const TextStyle(
                                color: AppColors.darkCharcoal,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['action'] ?? '',
                            style: AppTypography.tableCellSecondary,
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['device_info'] ?? 'Local',
                            style: AppTypography.tableCellSecondary,
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.softBorder.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '127.0.0.1', // Placeholder as IP isn't explicitly in activity_logs
                              style:  TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              color: AppColors.mutedText,
                            ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ), // Expanded
        ], // Column

      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.softBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon:  const Icon(
            Icons.arrow_drop_down,
            color: AppColors.mutedText,
          ),
          style: const TextStyle(
            color: AppColors.darkCharcoal,
            fontSize: 13,
          ),
          onChanged: onChanged,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: AppColors.mutedText,
                      ),
                      const SizedBox(width: 8),
                      Text(item),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
