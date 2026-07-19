import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ExportService {
  
  static Future<void> exportToCSV(List<Map<String, dynamic>> transactions, BuildContext context) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["Receipt No", "Date", "Items", "Payment", "Total", "Status"]);

      for (var tx in transactions) {
        final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
        
        rows.add([
          tx['receipt_number'] ?? '',
          formattedDate,
          tx['itemCount'] ?? 0,
          tx['payment_method'] ?? '',
          tx['total_amount'] ?? 0,
          tx['status'] ?? '',
        ]);
      }

      String csvData = rows.map((row) => row.join(',')).join('\n');
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(csvData);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to CSV: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  static Future<void> printPDF(List<Map<String, dynamic>> transactions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('N.Y Kitchen - Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                headers: ['Receipt No', 'Date', 'Total', 'Status'],
                data: transactions.map((tx) {
                  final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
                  final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
                  return [
                    tx['receipt_number'] ?? '',
                    formattedDate,
                    'Php ${tx['total_amount'] ?? 0}',
                    tx['status'] ?? ''
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
