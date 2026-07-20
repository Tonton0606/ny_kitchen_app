import 'package:flutter/material.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
import '../../../../../core/theme/app_colors.dart';

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
  String _dateFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final logs = await _auditRepo.getLogs(
      role: _roleFilter,
      date: _dateFilter,
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'System-wide security and audit trail records',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Logs'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldenYellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
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
                _buildFilterDropdown(
                  value: _dateFilter,
                  icon: Icons.date_range,
                  items: const ['All', 'Today'],
                  onChanged: (val) {
                    setState(() => _dateFilter = val!);
                    _onFilterChanged();
                  },
                ),
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Role',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Module',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Device',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'IP Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['username'] ?? 'System',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                              color: roleDisplay == 'Admin'
                                  ? AppColors.tertiary.withValues(alpha: 0.1)
                                  : (roleDisplay == 'Cashier'
                                        ? AppColors.goldenYellow.withValues(alpha: 0.1)
                                        : AppColors.mutedText.withValues(alpha: 0.1)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleDisplay,
                              style: TextStyle(
                                color: roleDisplay == 'Admin'
                                    ? AppColors.tertiary
                                    : (roleDisplay == 'Cashier'
                                          ? AppColors.goldenYellow
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
                            style: const TextStyle(fontSize: 13),
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
                            style: const TextStyle(fontSize: 13),
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
