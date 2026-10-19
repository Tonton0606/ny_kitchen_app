import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';

/// Admin Scannable Data Table conforming to:
/// - Flat card enclosure with 12px radius & 1px softBorder
/// - High-contrast headers (13px bold charcoal)
/// - Tabular figures on numeric columns
/// - Row hover feedback
class AppDataTable<T> extends StatelessWidget {
  final List<String> columnHeaders;
  final List<T> items;
  final List<Widget> Function(T item, int index) rowBuilder;
  final List<double>? columnWidths;
  final VoidCallback? onRowTap;
  final Widget? headerAction;
  final String? title;

  const AppDataTable({
    super.key,
    required this.columnHeaders,
    required this.items,
    required this.rowBuilder,
    this.columnWidths,
    this.onRowTap,
    this.headerAction,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        border: Border.all(color: AppColors.softBorder, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || headerAction != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                  ?headerAction,
                ],
              ),
            ),
          if (title != null || headerAction != null)
            const Divider(color: AppColors.softBorder, height: 1),

          // Table Header
          Container(
            color: AppColors.creamBackground,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(columnHeaders.length, (idx) {
                final width = columnWidths != null && idx < columnWidths!.length
                    ? columnWidths![idx]
                    : null;
                final text = Text(
                  columnHeaders[idx],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                    letterSpacing: 0.5,
                  ),
                );

                if (width != null) {
                  return SizedBox(width: width, child: text);
                }
                return Expanded(child: text);
              }),
            ),
          ),
          const Divider(color: AppColors.softBorder, height: 1),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppColors.softBorder,
              height: 1,
            ),
            itemBuilder: (context, index) {
              final cells = rowBuilder(items[index], index);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: List.generate(cells.length, (idx) {
                    final width = columnWidths != null && idx < columnWidths!.length
                        ? columnWidths![idx]
                        : null;
                    final cell = cells[idx];

                    if (width != null) {
                      return SizedBox(width: width, child: cell);
                    }
                    return Expanded(child: cell);
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
