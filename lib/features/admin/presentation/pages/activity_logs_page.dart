import 'package:flutter/material.dart';
import '../../../../../core/utils/mock_data.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/state_placeholders.dart';
import '../../../shared/widgets/status_badge.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  String _searchQuery = '';
  String _roleFilter = 'All';
  String _dateFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredLogs = MockData.logs.where((log) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!(log['user'] as String).toLowerCase().contains(query) &&
            !(log['action'] as String).toLowerCase().contains(query) &&
            !(log['module'] as String).toLowerCase().contains(query)) {
          return false;
        }
      }
      if (_roleFilter != 'All' && log['role'] != _roleFilter) return false;
      if (_dateFilter != 'All') {
        if (_dateFilter == 'Today' &&
            !(log['timestamp'] as String).contains('2026-07-14')) {
          return false;
        }
      }
      return true;
    }).toList();

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
                    Text(
                      'Activity Logs',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'System-wide security and audit trail records',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Export Logs'),
                  style: ElevatedButton.styleFrom(
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
                      onChanged: (val) => setState(() => _searchQuery = val),
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
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  value: _roleFilter,
                  icon: Icons.person_outline,
                  items: const ['All', 'Admin', 'Cashier', 'None'],
                  onChanged: (val) => setState(() => _roleFilter = val!),
                ),
                const SizedBox(width: 12),
                _buildFilterDropdown(
                  value: _dateFilter,
                  icon: Icons.date_range,
                  items: const ['All', 'Today'],
                  onChanged: (val) => setState(() => _dateFilter = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredLogs.isEmpty
                ? StatePlaceholders.empty(
                    context: context,
                    message: 'No activity logs match your filters.',
                    icon: Icons.security_outlined,
                  )
                : Card(
                    margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
              elevation: 0,
              child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
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
                    final isSuccess = log['status'] == 'Success';
                    final isFailed = log['status'] == 'Failed';
                    Color statusColor;
                    if (isSuccess) {
                      statusColor = AppColors.success;
                    } else if (isFailed) {
                      statusColor = Theme.of(context).colorScheme.error;
                    } else {
                      statusColor = Theme.of(context).colorScheme.tertiary;
                    }
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            log['timestamp'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['user'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        DataCell(
                          StatusBadge(
                            text: log['role'],
                            color: log['role'] == 'Admin'
                                ? Theme.of(context).colorScheme.tertiary
                                : (log['role'] == 'Cashier'
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                        DataCell(
                          StatusBadge(
                            text: log['module'],
                            color: Theme.of(context).colorScheme.onSurface,
                            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['action'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          StatusBadge(
                            text: log['status'],
                            color: statusColor,
                          ),
                        ),
                        DataCell(
                          Text(
                            log['device'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(
                          Text(
                            log['ip'],
                            style:  TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon:  Icon(
            Icons.arrow_drop_down,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          style:  TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
