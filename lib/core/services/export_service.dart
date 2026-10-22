import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;

/// Enterprise Export and Print Service for Sales Reports and Activity Logs.
/// Guarantees that sensitive credentials (password_hash, face_encoding, secrets)
/// are strictly excluded from all exports and printouts.
class ExportService {
  static const Set<String> _sensitiveKeys = {
    'password_hash',
    'face_encoding',
    'password',
    'secret',
    'service_key',
    'token',
  };

  /// Sanitizes records before reporting/exporting to guarantee no sensitive credentials leak.
  static Map<String, dynamic> sanitizeRecord(Map<String, dynamic> record) {
    final sanitized = <String, dynamic>{};
    for (final entry in record.entries) {
      final lowerKey = entry.key.toLowerCase();
      if (!_sensitiveKeys.contains(lowerKey)) {
        if (lowerKey == 'metadata') {
          sanitized[entry.key] = _sanitizeMetadata(entry.value);
        } else {
          sanitized[entry.key] = entry.value;
        }
      }
    }
    return sanitized;
  }

  static String _sanitizeMetadata(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    try {
      final decoded = json.decode(str);
      if (decoded is Map) {
        final cleaned = <String, dynamic>{};
        for (final entry in decoded.entries) {
          final keyStr = entry.key.toString().toLowerCase();
          if (!_sensitiveKeys.contains(keyStr)) {
            cleaned[entry.key.toString()] = entry.value;
          }
        }
        return json.encode(cleaned);
      }
    } catch (_) {
      // Plain string - return as is if not json
    }
    return str;
  }

  static Future<Directory> _getExportDirectory() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return Directory.systemTemp;
    }
  }

  // ==========================================
  // SALES REPORT GENERATORS
  // ==========================================

  static String _getCashierName(Map<String, dynamic> tx) {
    if (tx['cashier_role']?.toString().toLowerCase() == 'admin' ||
        tx['user_id'] == 1) {
      return 'Head Cashier';
    }
    final name = tx['cashier_name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      if (name.toLowerCase().contains('admin')) {
        return 'Head Cashier';
      }
      return name.trim();
    }
    final username = tx['cashier_username'] as String?;
    if (username != null && username.trim().isNotEmpty) {
      if (username.toLowerCase().contains('admin')) {
        return 'Head Cashier';
      }
      return username.trim();
    }
    return 'Head Cashier';
  }

  /// Generates PDF document for Sales Transactions (paginated MultiPage).
  static pw.Document generateSalesPdfDoc(List<Map<String, dynamic>> rawTransactions) {
    final pdf = pw.Document();
    final sanitized = rawTransactions.map(sanitizeRecord).toList();

    double grossAmount = 0.0;
    double voidedAmount = 0.0;
    int completedCount = 0;
    int voidedCount = 0;

    for (var tx in sanitized) {
      final status = (tx['status']?.toString() ?? 'Completed').trim().toLowerCase();
      final amountRaw = tx['total_amount'];
      final amount = amountRaw is num
          ? amountRaw.toDouble()
          : (double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0);

      grossAmount += amount;
      if (status == 'voided' || status == 'refunded') {
        voidedCount++;
        voidedAmount += amount;
      } else {
        completedCount++;
      }
    }

    final double totalRevenue = grossAmount - voidedAmount;

    final tableData = sanitized.map((tx) {
      final date = DateTime.tryParse(tx['created_at']?.toString() ?? '') ?? DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
      final amountRaw = tx['total_amount'];
      final amount = amountRaw is num
          ? amountRaw.toDouble()
          : (double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0);
      final cashier = _getCashierName(tx);

      return [
        tx['receipt_number']?.toString() ?? 'N/A',
        formattedDate,
        cashier,
        tx['itemCount']?.toString() ?? '1',
        tx['payment_method']?.toString() ?? 'Cash',
        'Php ${amount.toStringAsFixed(2)}',
        tx['status']?.toString() ?? 'Completed',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'N.Y Kitchen - Sales Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown900,
                  ),
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Valid Orders: $completedCount  |  Voided/Refunded: $voidedCount (Php ${voidedAmount.toStringAsFixed(2)})  |  Net Revenue: Php ${totalRevenue.toStringAsFixed(2)}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (pw.Context context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (pw.Context context) => [
          if (tableData.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 32),
                child: pw.Text(
                  'No transactions recorded for the selected period.',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Receipt No', 'Date', 'Cashier', 'Items', 'Payment', 'Total', 'Status'],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown800),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
                6: pw.Alignment.center,
              },
            ),
        ],
      ),
    );
    return pdf;
  }

  /// Generates PDF bytes for Sales Transactions.
  static Future<Uint8List> generateSalesPdfBytes(List<Map<String, dynamic>> rawTransactions) async {
    final pdf = generateSalesPdfDoc(rawTransactions);
    return await pdf.save();
  }

  /// Generates Excel bytes for Sales Transactions.
  static List<int> generateSalesExcelBytes(List<Map<String, dynamic>> rawTransactions) {
    final sanitized = rawTransactions.map(sanitizeRecord).toList();
    final workbook = excel.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Sales Report';

    // Headers
    sheet.getRangeByName('A1').setText('Receipt No');
    sheet.getRangeByName('B1').setText('Date');
    sheet.getRangeByName('C1').setText('Cashier');
    sheet.getRangeByName('D1').setText('Items');
    sheet.getRangeByName('E1').setText('Payment');
    sheet.getRangeByName('F1').setText('Total');
    sheet.getRangeByName('G1').setText('Status');

    final headerRange = sheet.getRangeByName('A1:G1');
    headerRange.cellStyle.bold = true;

    sheet.setColumnWidthInPixels(1, 120);
    sheet.setColumnWidthInPixels(2, 160);
    sheet.setColumnWidthInPixels(3, 140);
    sheet.setColumnWidthInPixels(4, 70);
    sheet.setColumnWidthInPixels(5, 100);
    sheet.setColumnWidthInPixels(6, 120);
    sheet.setColumnWidthInPixels(7, 100);

    int row = 2;
    double grossTotal = 0.0;
    double voidedTotal = 0.0;

    for (var tx in sanitized) {
      final date = DateTime.tryParse(tx['created_at']?.toString() ?? '') ?? DateTime.now();
      final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date);
      final cashier = _getCashierName(tx);

      final amountRaw = tx['total_amount'];
      final amount = amountRaw is num
          ? amountRaw.toDouble()
          : (double.tryParse(amountRaw?.toString() ?? '0') ?? 0.0);

      final status = (tx['status']?.toString() ?? 'Completed').trim();
      final statusLower = status.toLowerCase();

      grossTotal += amount;
      if (statusLower == 'voided' || statusLower == 'refunded') {
        voidedTotal += amount;
      }

      sheet.getRangeByIndex(row, 1).setText(tx['receipt_number']?.toString() ?? '');
      sheet.getRangeByIndex(row, 2).setText(formattedDate);
      sheet.getRangeByIndex(row, 3).setText(cashier);
      sheet.getRangeByIndex(row, 4).setNumber((tx['itemCount'] ?? 1).toDouble());
      sheet.getRangeByIndex(row, 5).setText(tx['payment_method']?.toString() ?? 'Cash');
      sheet.getRangeByIndex(row, 6).setNumber(amount);
      sheet.getRangeByIndex(row, 7).setText(status);

      row++;
    }

    final double netTotal = grossTotal - voidedTotal;

    if (row > 2) {
      final totalCol = sheet.getRangeByName('F2:F${row - 1}');
      totalCol.cellStyle.numberFormat = '₱#,##0.00';

      // 1. GROSS TOTAL
      sheet.getRangeByIndex(row, 5).setText('GROSS TOTAL');
      sheet.getRangeByIndex(row, 5).cellStyle.bold = true;
      final grossRange = sheet.getRangeByIndex(row, 6);
      grossRange.setNumber(grossTotal);
      grossRange.cellStyle.bold = true;
      grossRange.cellStyle.numberFormat = '₱#,##0.00';

      // 2. LESS VOIDED / REFUNDED
      sheet.getRangeByIndex(row + 1, 5).setText('LESS VOIDED / REFUNDED');
      sheet.getRangeByIndex(row + 1, 5).cellStyle.bold = true;
      final voidedRange = sheet.getRangeByIndex(row + 1, 6);
      voidedRange.setNumber(-voidedTotal.abs());
      voidedRange.cellStyle.bold = true;
      voidedRange.cellStyle.numberFormat = '₱#,##0.00; -₱#,##0.00; ₱0.00';

      // 3. NET TOTAL REVENUE
      sheet.getRangeByIndex(row + 2, 5).setText('NET TOTAL REVENUE');
      sheet.getRangeByIndex(row + 2, 5).cellStyle.bold = true;
      final netRange = sheet.getRangeByIndex(row + 2, 6);
      netRange.setNumber(netTotal);
      netRange.cellStyle.bold = true;
      netRange.cellStyle.numberFormat = '₱#,##0.00';
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  // ==========================================
  // ACTIVITY LOGS GENERATORS
  // ==========================================

  /// Generates PDF document for Activity Logs (paginated MultiPage).
  static pw.Document generateLogsPdfDoc(List<Map<String, dynamic>> rawLogs) {
    final pdf = pw.Document();
    final sanitized = rawLogs.map(sanitizeRecord).toList();

    final tableData = sanitized.map((log) {
      final dateStr = log['timestamp']?.toString() ?? log['created_at']?.toString() ?? '';
      String formattedDate = dateStr;
      if (dateStr.isNotEmpty) {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(parsed);
        }
      }

      final role = log['role']?.toString() ?? '';
      final roleDisplay = role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : 'User';

      return [
        formattedDate,
        log['username']?.toString() ?? 'System',
        roleDisplay,
        log['module']?.toString() ?? '',
        log['action']?.toString() ?? '',
        log['status']?.toString() ?? '',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'N.Y Kitchen - Activity & Audit Trail Logs',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown900,
                  ),
                ),
                pw.Text(
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Total Audit Events: ${sanitized.length}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (pw.Context context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (pw.Context context) => [
          if (tableData.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 32),
                child: pw.Text(
                  'No audit log entries recorded.',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                ),
              ),
            )
          else
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Timestamp', 'User', 'Role', 'Module', 'Action', 'Status'],
              data: tableData,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.brown800),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );
    return pdf;
  }

  /// Generates PDF bytes for Activity Logs.
  static Future<Uint8List> generateLogsPdfBytes(List<Map<String, dynamic>> rawLogs) async {
    final pdf = generateLogsPdfDoc(rawLogs);
    return await pdf.save();
  }

  /// Generates Excel bytes for Activity Logs.
  static List<int> generateLogsExcelBytes(List<Map<String, dynamic>> rawLogs) {
    final sanitized = rawLogs.map(sanitizeRecord).toList();
    final workbook = excel.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Activity Logs';

    sheet.getRangeByName('A1').setText('Timestamp');
    sheet.getRangeByName('B1').setText('User');
    sheet.getRangeByName('C1').setText('Role');
    sheet.getRangeByName('D1').setText('Module');
    sheet.getRangeByName('E1').setText('Action');
    sheet.getRangeByName('F1').setText('Status');
    sheet.getRangeByName('G1').setText('Description');

    final headerRange = sheet.getRangeByName('A1:G1');
    headerRange.cellStyle.bold = true;

    sheet.setColumnWidthInPixels(1, 150);
    sheet.setColumnWidthInPixels(2, 120);
    sheet.setColumnWidthInPixels(3, 80);
    sheet.setColumnWidthInPixels(4, 120);
    sheet.setColumnWidthInPixels(5, 180);
    sheet.setColumnWidthInPixels(6, 100);
    sheet.setColumnWidthInPixels(7, 240);

    int row = 2;
    for (var log in sanitized) {
      final dateStr = log['timestamp']?.toString() ?? log['created_at']?.toString() ?? '';
      String formattedDate = dateStr;
      if (dateStr.isNotEmpty) {
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(parsed);
        }
      }

      final role = log['role']?.toString() ?? '';
      final roleDisplay = role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : 'User';

      sheet.getRangeByIndex(row, 1).setText(formattedDate);
      sheet.getRangeByIndex(row, 2).setText(log['username']?.toString() ?? 'System');
      sheet.getRangeByIndex(row, 3).setText(roleDisplay);
      sheet.getRangeByIndex(row, 4).setText(log['module']?.toString() ?? '');
      sheet.getRangeByIndex(row, 5).setText(log['action']?.toString() ?? '');
      sheet.getRangeByIndex(row, 6).setText(log['status']?.toString() ?? '');
      sheet.getRangeByIndex(row, 7).setText(log['description']?.toString() ?? '');

      row++;
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  // ==========================================
  // PRINT & EXPORT ACTION HANDLERS
  // ==========================================

  /// Prints Sales Report PDF using system print dialogue.
  static Future<bool> printPDF(List<Map<String, dynamic>> transactions) async {
    final pdfBytes = await generateSalesPdfBytes(transactions);
    return await Printing.layoutPdf(
      name: 'sales_report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Exports Sales Report to PDF file on disk.
  static Future<File?> exportToPDF(
    List<Map<String, dynamic>> transactions, [
    BuildContext? context,
  ]) async {
    try {
      final bytes = await generateSalesPdfBytes(transactions);
      final directory = await _getExportDirectory();
      final path = '${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to PDF: $path'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return file;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Exports Sales Report to Excel (.xlsx) file on disk.
  static Future<File?> exportToExcel(
    List<Map<String, dynamic>> transactions, [
    BuildContext? context,
  ]) async {
    try {
      final bytes = generateSalesExcelBytes(transactions);
      final directory = await _getExportDirectory();
      final path = '${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported to Excel: $path'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return file;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Excel: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Prints Activity Logs PDF using system print dialogue.
  static Future<bool> printLogsPDF(List<Map<String, dynamic>> logs) async {
    final pdfBytes = await generateLogsPdfBytes(logs);
    return await Printing.layoutPdf(
      name: 'activity_logs_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf',
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }

  /// Exports Activity Logs to PDF file on disk.
  static Future<File?> exportLogsToPDF(
    List<Map<String, dynamic>> logs, [
    BuildContext? context,
  ]) async {
    try {
      final bytes = await generateLogsPdfBytes(logs);
      final directory = await _getExportDirectory();
      final path = '${directory.path}/activity_logs_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported Logs to PDF: $path'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return file;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Logs to PDF: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  /// Exports Activity Logs to Excel (.xlsx) file on disk.
  static Future<File?> exportLogsToExcel(
    List<Map<String, dynamic>> logs, [
    BuildContext? context,
  ]) async {
    try {
      final bytes = generateLogsExcelBytes(logs);
      final directory = await _getExportDirectory();
      final path = '${directory.path}/activity_logs_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported Logs to Excel: $path'),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return file;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export Logs to Excel: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }
}
