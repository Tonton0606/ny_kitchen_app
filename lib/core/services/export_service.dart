import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;

class ExportService {
  
  static Future<void> exportToCSV(List<Map<String, dynamic>> transactions, BuildContext context) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(["Receipt No", "Date", "Items", "Payment", "Total", "Status"]);

      for (var tx in transactions) {
        final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
        
        final amountRaw = tx['total_amount'];
        final amount = amountRaw is num ? amountRaw.toDouble() : (double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0);

        rows.add([
          tx['receipt_number'] ?? '',
          formattedDate,
          tx['itemCount'] ?? 0,
          tx['payment_method'] ?? '',
          amount,
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

  static Future<void> exportToExcel(List<Map<String, dynamic>> transactions, BuildContext context) async {
    try {
      final workbook = excel.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Sales Report';
      
      // Headers
      sheet.getRangeByName('A1').setText('Receipt No');
      sheet.getRangeByName('B1').setText('Date');
      sheet.getRangeByName('C1').setText('Items');
      sheet.getRangeByName('D1').setText('Payment');
      sheet.getRangeByName('E1').setText('Total');
      sheet.getRangeByName('F1').setText('Status');

      final headerRange = sheet.getRangeByName('A1:F1');
      headerRange.cellStyle.bold = true;

      // Set column widths
      sheet.setColumnWidthInPixels(1, 120);
      sheet.setColumnWidthInPixels(2, 160);
      sheet.setColumnWidthInPixels(3, 80);
      sheet.setColumnWidthInPixels(4, 100);
      sheet.setColumnWidthInPixels(5, 120);
      sheet.setColumnWidthInPixels(6, 100);

      int row = 2;
      for (var tx in transactions) {
        final date = DateTime.tryParse(tx['created_at'] ?? '') ?? DateTime.now();
        final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
        
        final amountRaw = tx['total_amount'];
        final amount = amountRaw is num ? amountRaw.toDouble() : (double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0);

        sheet.getRangeByIndex(row, 1).setText(tx['receipt_number']?.toString() ?? '');
        sheet.getRangeByIndex(row, 2).setText(formattedDate);
        sheet.getRangeByIndex(row, 3).setNumber((tx['itemCount'] ?? 0).toDouble());
        sheet.getRangeByIndex(row, 4).setText(tx['payment_method']?.toString() ?? '');
        sheet.getRangeByIndex(row, 5).setNumber(amount);
        sheet.getRangeByIndex(row, 6).setText(tx['status']?.toString() ?? '');
        
        row++;
      }

      // Formula for Summation
      if (row > 2) {
        sheet.getRangeByIndex(row, 4).setText('TOTAL SUM');
        sheet.getRangeByIndex(row, 4).cellStyle.bold = true;
        
        final sumRange = sheet.getRangeByIndex(row, 5);
        sumRange.setFormula('=SUM(E2:E${row - 1})');
        sumRange.cellStyle.bold = true;
        sumRange.cellStyle.numberFormat = '₱#,##0.00';
      }

      // Format currency for the total column
      if (row > 2) {
        final totalCol = sheet.getRangeByName('E2:E${row - 1}');
        totalCol.cellStyle.numberFormat = '₱#,##0.00';
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to Excel: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Excel: $e')),
        );
      }
    }
  }

  static pw.Document _generatePdfDoc(List<Map<String, dynamic>> transactions) {
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
                  
                  final amountRaw = tx['total_amount'];
                  final amount = amountRaw is num ? amountRaw.toDouble() : (double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0);
                  
                  return [
                    tx['receipt_number'] ?? '',
                    formattedDate,
                    'Php ${amount.toStringAsFixed(2)}',
                    tx['status'] ?? ''
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> printPDF(List<Map<String, dynamic>> transactions) async {
    final pdf = _generatePdfDoc(transactions);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> exportToPDF(List<Map<String, dynamic>> transactions, BuildContext context) async {
    try {
      final pdf = _generatePdfDoc(transactions);
      final bytes = await pdf.save();
      
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to PDF: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: $e')),
        );
      }
    }
  }

  static Future<void> exportLogsToExcel(List<Map<String, dynamic>> logs, BuildContext context) async {
    try {
      final workbook = excel.Workbook();
      final sheet = workbook.worksheets[0];
      sheet.name = 'Activity Logs';
      
      // Headers
      sheet.getRangeByName('A1').setText('Timestamp');
      sheet.getRangeByName('B1').setText('User');
      sheet.getRangeByName('C1').setText('Role');
      sheet.getRangeByName('D1').setText('Module');
      sheet.getRangeByName('E1').setText('Action');
      sheet.getRangeByName('F1').setText('Status');
      sheet.getRangeByName('G1').setText('Device');

      final headerRange = sheet.getRangeByName('A1:G1');
      headerRange.cellStyle.bold = true;

      // Set column widths
      sheet.setColumnWidthInPixels(1, 150);
      sheet.setColumnWidthInPixels(2, 120);
      sheet.setColumnWidthInPixels(3, 80);
      sheet.setColumnWidthInPixels(4, 120);
      sheet.setColumnWidthInPixels(5, 180);
      sheet.setColumnWidthInPixels(6, 100);
      sheet.setColumnWidthInPixels(7, 100);

      int row = 2;
      for (var log in logs) {
        final dateStr = log['created_at'] ?? '';
        String formattedDate = dateStr;
        if (dateStr.isNotEmpty) {
          final parsedDate = DateTime.tryParse(dateStr);
          if (parsedDate != null) {
            formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
          }
        }

        final role = log['role'] as String? ?? '';
        final roleDisplay = role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : '';

        sheet.getRangeByIndex(row, 1).setText(formattedDate);
        sheet.getRangeByIndex(row, 2).setText(log['username'] ?? 'System');
        sheet.getRangeByIndex(row, 3).setText(roleDisplay);
        sheet.getRangeByIndex(row, 4).setText(log['module'] ?? '');
        sheet.getRangeByIndex(row, 5).setText(log['action'] ?? '');
        sheet.getRangeByIndex(row, 6).setText(log['status'] ?? '');
        sheet.getRangeByIndex(row, 7).setText(log['device_info'] ?? 'Local');
        
        row++;
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/activity_logs_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported Logs to Excel: $path')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export Logs to Excel: $e')),
        );
      }
    }
  }
}
