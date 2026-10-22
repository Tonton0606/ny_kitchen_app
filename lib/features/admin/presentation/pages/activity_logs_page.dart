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

  int _currentPage = 1;
  static const int _pageSize = 10;
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _verticalScrollController.dispose();
    super.dispose();
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
        _currentPage = 1;
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
              : Builder(
                  builder: (context) {
                    final totalLogs = filteredLogs.length;
                    final totalPages = (totalLogs / _pageSize).ceil().clamp(1, 9999);
                    final currentPage = _currentPage.clamp(1, totalPages);
                    final startIndex = (currentPage - 1) * _pageSize;
                    final endIndex = (startIndex + _pageSize).clamp(0, totalLogs);
                    final pageLogs = totalLogs > 0 ? filteredLogs.sublist(startIndex, endIndex) : <Map<String, dynamic>>[];

                    return Container(
                      margin: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.softBorder),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: filteredLogs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No activity logs found matching your filters.',
                                      style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Scrollbar(
                                        controller: _verticalScrollController,
                                        thumbVisibility: true,
                                        child: SingleChildScrollView(
                                          controller: _verticalScrollController,
                                          scrollDirection: Axis.vertical,
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                              child: DataTable(
                                                headingRowColor: WidgetStateProperty.all(const Color(0xFFFAF8F5)),
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
                                                rows: pageLogs.map((log) {
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
                                                          child: const Text(
                                                            '127.0.0.1',
                                                            style: TextStyle(
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
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: AppColors.softBorder)),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  filteredLogs.isEmpty
                                      ? 'Showing 0 logs'
                                      : 'Showing ${startIndex + 1}–$endIndex of $totalLogs logs',
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                if (totalPages > 1)
                                  _buildPaginationControls(currentPage, totalPages),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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

  Widget _buildPaginationControls(int currentPage, int totalPages) {
    final List<int> pages = [];
    if (totalPages <= 7) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      if (currentPage <= 4) {
        pages.addAll([1, 2, 3, 4, 5, -1, totalPages]);
      } else if (currentPage >= totalPages - 3) {
        pages.addAll([
          1,
          -1,
          totalPages - 4,
          totalPages - 3,
          totalPages - 2,
          totalPages - 1,
          totalPages,
        ]);
      } else {
        pages.addAll([
          1,
          -1,
          currentPage - 1,
          currentPage,
          currentPage + 1,
          -1,
          totalPages,
        ]);
      }
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: currentPage > 1
              ? () => setState(() => _currentPage = currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left, size: 20),
          color: AppColors.darkCharcoal,
          disabledColor: AppColors.mutedText.withValues(alpha: 0.35),
          tooltip: 'Previous page',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 32, maxHeight: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        ...pages.map((p) {
          if (p == -1) {
            return const SizedBox(
              width: 24,
              height: 32,
              child: Center(
                child: Text(
                  '...',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }
          final isSelected = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _currentPage = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldenYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.softBorder),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.black : AppColors.darkCharcoal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => setState(() => _currentPage = currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right, size: 20),
          color: AppColors.darkCharcoal,
          disabledColor: AppColors.mutedText.withValues(alpha: 0.35),
          tooltip: 'Next page',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 32, maxHeight: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
