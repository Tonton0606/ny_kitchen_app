import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../../core/database/repositories/audit_repository.dart';
import '../../../../../core/services/export_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../shared/widgets/app_status_chip.dart';
import '../../../shared/widgets/app_state_placeholders.dart';

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
    final filteredLogs = _logs;
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(100),
                      ],
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                        _onFilterChanged();
                      },
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        hintText: 'Search users, actions, or modules...',
                        hintStyle: AppTypography.bodyMuted,
                        prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.mutedSlate),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                          borderSide: const BorderSide(color: AppColors.softBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                          borderSide: const BorderSide(color: AppColors.softBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                          borderSide: const BorderSide(color: AppColors.darkCharcoal, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        filled: true,
                        fillColor: AppColors.surfaceWhite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDesignTokens.space12),
                _buildFilterDropdown(
                  value: _roleFilter,
                  icon: Icons.person_outline,
                  items: const ['All', 'admin', 'cashier', 'None'],
                  onChanged: (val) {
                    setState(() => _roleFilter = val!);
                    _onFilterChanged();
                  },
                ),
                const SizedBox(width: AppDesignTokens.space12),
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
                              surface: AppColors.surfaceWhite,
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
                    style: AppTypography.buttonSmall,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.softBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    ),
                    backgroundColor: AppColors.surfaceWhite,
                  ),
                ),
                if (_selectedDateRange != null) ...[
                  const SizedBox(width: AppDesignTokens.space8),
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
                const SizedBox(width: AppDesignTokens.space16),
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
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print', style: AppTypography.buttonSmall),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkCharcoal,
                    side: const BorderSide(color: AppColors.softBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    ),
                    backgroundColor: AppColors.surfaceWhite,
                  ),
                ),
                const SizedBox(width: AppDesignTokens.space8),
                PopupMenuButton<String>(
                  offset: const Offset(0, 42),
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
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'excel',
                      child: Text('Export as Excel (.xlsx)', style: AppTypography.body),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Text('Export as PDF (.pdf)', style: AppTypography.body),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.goldenYellow,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_rounded, size: 18, color: AppColors.darkCharcoal),
                        SizedBox(width: 8),
                        Text('Export', style: AppTypography.buttonSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table & Data Panel
          Expanded(
            child: _isLoading 
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCharcoal),
                  ),
                )
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
                        color: AppColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                        border: Border.all(color: AppColors.softBorder),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: filteredLogs.isEmpty
                                ? const AppEmptyState(
                                    icon: Icons.history_rounded,
                                    title: 'No activity logs found',
                                    subtitle: 'Adjust your search or date filters to find matching records.',
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
                                                headingRowColor: WidgetStateProperty.all(AppColors.creamBackground),
                                                headingRowHeight: 46,
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
                                                                ? AppColors.inkBlue.withValues(alpha: 0.12)
                                                                : (roleDisplay == 'Cashier'
                                                                      ? AppColors.goldenYellow
                                                                      : AppColors.mutedSlate.withValues(alpha: 0.1)),
                                                            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                                                          ),
                                                          child: Text(
                                                            roleDisplay,
                                                            style: AppTypography.label.copyWith(
                                                              color: roleDisplay == 'Admin'
                                                                  ? AppColors.inkBlue
                                                                  : AppColors.darkCharcoal,
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
                                                            color: AppColors.creamBackground,
                                                            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                                                            border: Border.all(color: AppColors.softBorder),
                                                          ),
                                                          child: Text(
                                                            log['module'] ?? '',
                                                            style: AppTypography.bodyMuted.copyWith(
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
                                                        AppStatusChip(
                                                          label: status,
                                                          type: isSuccess
                                                              ? AppStatusType.success
                                                              : (isFailed
                                                                  ? AppStatusType.error
                                                                  : AppStatusType.info),
                                                          isCompact: true,
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
                                                            color: AppColors.creamBackground,
                                                            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                                                          ),
                                                          child: const Text(
                                                            '127.0.0.1',
                                                            style: TextStyle(
                                                              fontFamily: 'monospace',
                                                              fontSize: 12,
                                                              color: AppColors.mutedSlate,
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
                          // Pagination Controls
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
                                  style: AppTypography.label12.copyWith(color: AppColors.mutedSlate),
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
        color: AppColors.surfaceWhite,
        border: Border.all(color: AppColors.softBorder),
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: AppColors.mutedSlate,
          ),
          style: AppTypography.buttonSmall,
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
                        color: AppColors.mutedSlate,
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
          disabledColor: AppColors.mutedSlate.withValues(alpha: 0.35),
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
                  style: AppTypography.label,
                ),
              ),
            );
          }
          final isSelected = p == currentPage;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              onTap: () => setState(() => _currentPage = p),
              child: AnimatedContainer(
                duration: AppDesignTokens.motionFast,
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.goldenYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.softBorder),
                ),
                child: Center(
                  child: Text(
                    '$p',
                    style: AppTypography.figureSmall.copyWith(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.darkCharcoal,
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
          disabledColor: AppColors.mutedSlate.withValues(alpha: 0.35),
          tooltip: 'Next page',
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32, maxWidth: 32, maxHeight: 32),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

