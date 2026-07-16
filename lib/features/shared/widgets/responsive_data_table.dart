import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

class ResponsiveDataTable<T> extends StatelessWidget {
  final List<String> columns;
  final List<T> data;
  final DataRow Function(T item) buildRow;
  final Widget Function(T item) buildCard;

  const ResponsiveDataTable({
    super.key,
    required this.columns,
    required this.data,
    required this.buildRow,
    required this.buildCard,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox.shrink(); // Handled by StatePlaceholders.empty usually
    }

    if (Responsive.isMobile(context)) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: buildCard(data[index]),
              ),
            ),
          );
        },
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns
            .map(
              (e) => DataColumn(
                label: Text(
                  e,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: data.map((e) => buildRow(e)).toList(),
      ),
    );
  }
}
