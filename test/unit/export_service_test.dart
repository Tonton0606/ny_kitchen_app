import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Track 2 - Reporting Actions: ExportService Security & Sanitization', () {
    test('sanitizeRecord removes password_hash, face_encoding, and other credential fields', () {
      final inputRecord = {
        'id': 101,
        'username': 'cashier1',
        'role': 'cashier',
        'password_hash': '600000:salt:hash_secret',
        'face_encoding': 'v2:nonce:cipher_biometrics',
        'password': 'plain_text_password',
        'secret': 'super_secret_value',
        'service_key': 'internal_service_key',
        'token': 'bearer_token_xyz',
        'total_amount': 250.0,
      };

      final sanitized = ExportService.sanitizeRecord(inputRecord);

      expect(sanitized.containsKey('password_hash'), isFalse,
          reason: 'password_hash must be stripped');
      expect(sanitized.containsKey('face_encoding'), isFalse,
          reason: 'face_encoding must be stripped');
      expect(sanitized.containsKey('password'), isFalse,
          reason: 'password must be stripped');
      expect(sanitized.containsKey('secret'), isFalse,
          reason: 'secret must be stripped');
      expect(sanitized.containsKey('service_key'), isFalse,
          reason: 'service_key must be stripped');
      expect(sanitized.containsKey('token'), isFalse,
          reason: 'token must be stripped');
      expect(sanitized['id'], equals(101));
      expect(sanitized['username'], equals('cashier1'));
      expect(sanitized['total_amount'], equals(250.0));
    });

    test('sanitizeRecord purges sensitive credential keys embedded in JSON metadata strings', () {
      final inputRecord = {
        'id': 202,
        'action': 'USER_UPDATED',
        'metadata': json.encode({
          'user_id': 5,
          'password_hash': '600000:metadata_hash',
          'face_encoding': 'v2:metadata_face_cipher',
          'role': 'admin',
        }),
      };

      final sanitized = ExportService.sanitizeRecord(inputRecord);
      final metadataStr = sanitized['metadata'] as String;

      expect(metadataStr.contains('password_hash'), isFalse,
          reason: 'password_hash inside metadata JSON must be purged');
      expect(metadataStr.contains('face_encoding'), isFalse,
          reason: 'face_encoding inside metadata JSON must be purged');
      expect(metadataStr.contains('user_id'), isTrue);
      expect(metadataStr.contains('admin'), isTrue);
    });

    test('generateSalesPdfBytes and generateSalesExcelBytes never leak sensitive credentials in output', () async {
      const secretHash = 'LEAK_CHECK_HASH_99999';
      const secretFace = 'LEAK_CHECK_FACE_88888';

      final poisonedTransactions = [
        {
          'id': 1,
          'receipt_number': 'REC-1001',
          'created_at': '2026-10-16T10:00:00Z',
          'itemCount': 3,
          'payment_method': 'Cash',
          'total_amount': 350.00,
          'status': 'Completed',
          'password_hash': secretHash,
          'face_encoding': secretFace,
        },
      ];

      final pdfBytes = await ExportService.generateSalesPdfBytes(poisonedTransactions);
      final pdfString = utf8.decode(pdfBytes, allowMalformed: true);
      expect(pdfString.contains(secretHash), isFalse,
          reason: 'Sales PDF must never contain password_hash');
      expect(pdfString.contains(secretFace), isFalse,
          reason: 'Sales PDF must never contain face_encoding');

      final excelBytes = ExportService.generateSalesExcelBytes(poisonedTransactions);
      final excelString = utf8.decode(excelBytes, allowMalformed: true);
      expect(excelString.contains(secretHash), isFalse,
          reason: 'Sales Excel must never contain password_hash');
      expect(excelString.contains(secretFace), isFalse,
          reason: 'Sales Excel must never contain face_encoding');
    });

    test('generateLogsPdfBytes and generateLogsExcelBytes never leak sensitive credentials in output', () async {
      const secretHash = 'LEAK_CHECK_LOG_HASH_77777';
      const secretFace = 'LEAK_CHECK_LOG_FACE_66666';

      final poisonedLogs = [
        {
          'id': 1,
          'timestamp': '2026-10-16T10:15:00Z',
          'username': 'admin',
          'role': 'admin',
          'module': 'AUTH',
          'action': 'LOGIN',
          'status': 'SUCCESS',
          'description': 'Admin user logged in',
          'password_hash': secretHash,
          'face_encoding': secretFace,
          'metadata': json.encode({'password_hash': secretHash, 'face_encoding': secretFace}),
        },
      ];

      final pdfBytes = await ExportService.generateLogsPdfBytes(poisonedLogs);
      final pdfString = utf8.decode(pdfBytes, allowMalformed: true);
      expect(pdfString.contains(secretHash), isFalse,
          reason: 'Logs PDF must never contain password_hash');
      expect(pdfString.contains(secretFace), isFalse,
          reason: 'Logs PDF must never contain face_encoding');

      final excelBytes = ExportService.generateLogsExcelBytes(poisonedLogs);
      final excelString = utf8.decode(excelBytes, allowMalformed: true);
      expect(excelString.contains(secretHash), isFalse,
          reason: 'Logs Excel must never contain password_hash');
      expect(excelString.contains(secretFace), isFalse,
          reason: 'Logs Excel must never contain face_encoding');
    });
  });

  group('Track 2 - Reporting Actions: File Contents & Signatures', () {
    final sampleTransactions = [
      {
        'id': 1,
        'receipt_number': 'REC-001',
        'created_at': '2026-10-16T08:30:00Z',
        'itemCount': 2,
        'payment_method': 'Cash',
        'total_amount': 220.50,
        'status': 'Completed',
      },
      {
        'id': 2,
        'receipt_number': 'REC-002',
        'created_at': '2026-10-16T09:45:00Z',
        'itemCount': 1,
        'payment_method': 'GCash',
        'total_amount': 150.00,
        'status': 'Completed',
      },
    ];

    final sampleLogs = [
      {
        'id': 1,
        'timestamp': '2026-10-16T08:00:00Z',
        'username': 'admin',
        'role': 'admin',
        'module': 'USER',
        'action': 'LOGIN',
        'status': 'SUCCESS',
        'description': 'User logged in successfully',
      },
      {
        'id': 2,
        'timestamp': '2026-10-16T08:05:00Z',
        'username': 'cashier1',
        'role': 'cashier',
        'module': 'POS',
        'action': 'ORDER_CREATED',
        'status': 'SUCCESS',
        'description': 'Created order REC-001',
      },
    ];

    test('generateSalesPdfBytes produces valid PDF format (%PDF- signature)', () async {
      final pdfBytes = await ExportService.generateSalesPdfBytes(sampleTransactions);
      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF files start with %PDF- (hex: 25 50 44 46 2D)
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateSalesExcelBytes produces valid XLSX format (PK signature)', () {
      final excelBytes = ExportService.generateSalesExcelBytes(sampleTransactions);
      expect(excelBytes.isNotEmpty, isTrue);
      // Valid OOXML / XLSX files are ZIP archives starting with PK (0x50, 0x4B)
      expect(excelBytes[0], equals(0x50));
      expect(excelBytes[1], equals(0x4B));
    });

    test('generateLogsPdfBytes produces valid PDF format (%PDF- signature)', () async {
      final pdfBytes = await ExportService.generateLogsPdfBytes(sampleLogs);
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateLogsExcelBytes produces valid XLSX format (PK signature)', () {
      final excelBytes = ExportService.generateLogsExcelBytes(sampleLogs);
      expect(excelBytes.isNotEmpty, isTrue);
      expect(excelBytes[0], equals(0x50));
      expect(excelBytes[1], equals(0x4B));
    });
  });

  group('Track 2 - Reporting Actions: Empty Data Handling', () {
    test('generateSalesPdfBytes handles empty transaction list gracefully', () async {
      final pdfBytes = await ExportService.generateSalesPdfBytes([]);
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateSalesExcelBytes handles empty transaction list gracefully', () {
      final excelBytes = ExportService.generateSalesExcelBytes([]);
      expect(excelBytes.isNotEmpty, isTrue);
      expect(excelBytes[0], equals(0x50));
      expect(excelBytes[1], equals(0x4B));
    });

    test('generateLogsPdfBytes handles empty logs list gracefully', () async {
      final pdfBytes = await ExportService.generateLogsPdfBytes([]);
      expect(pdfBytes.isNotEmpty, isTrue);
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generateLogsExcelBytes handles empty logs list gracefully', () {
      final excelBytes = ExportService.generateLogsExcelBytes([]);
      expect(excelBytes.isNotEmpty, isTrue);
      expect(excelBytes[0], equals(0x50));
      expect(excelBytes[1], equals(0x4B));
    });
  });

  group('Track 2 - Reporting Actions: Large Data Resilience', () {
    test('generateSalesPdfBytes and generateSalesExcelBytes handle 500+ records cleanly without overflow', () async {
      final largeTransactions = List.generate(500, (index) {
        return {
          'id': index + 1,
          'receipt_number': 'REC-${1000 + index}',
          'created_at': DateTime.now().subtract(Duration(minutes: index * 5)).toIso8601String(),
          'itemCount': (index % 5) + 1,
          'payment_method': index % 2 == 0 ? 'Cash' : 'GCash',
          'total_amount': 50.0 + (index * 2.5),
          'status': index % 10 == 0 ? 'Voided' : 'Completed',
        };
      });

      final pdfBytes = await ExportService.generateSalesPdfBytes(largeTransactions);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(10000), reason: 'MultiPage PDF should contain substantive data');

      final excelBytes = ExportService.generateSalesExcelBytes(largeTransactions);
      expect(excelBytes.isNotEmpty, isTrue);
      expect(excelBytes.length, greaterThan(10000));
    });

    test('generateLogsPdfBytes and generateLogsExcelBytes handle 500+ records cleanly without overflow', () async {
      final largeLogs = List.generate(500, (index) {
        return {
          'id': index + 1,
          'timestamp': DateTime.now().subtract(Duration(minutes: index * 2)).toIso8601String(),
          'username': index % 3 == 0 ? 'admin' : 'cashier${index % 5}',
          'role': index % 3 == 0 ? 'admin' : 'cashier',
          'module': index % 2 == 0 ? 'TRANSACTIONS' : 'FOOD_INVENTORY',
          'action': index % 2 == 0 ? 'ORDER_COMPLETED' : 'ITEM_UPDATED',
          'status': 'SUCCESS',
          'description': 'Automated log event record #$index',
        };
      });

      final pdfBytes = await ExportService.generateLogsPdfBytes(largeLogs);
      expect(pdfBytes.isNotEmpty, isTrue);
      expect(pdfBytes.length, greaterThan(10000), reason: 'MultiPage PDF should paginate cleanly across pages');

      final excelBytes = ExportService.generateLogsExcelBytes(largeLogs);
      expect(excelBytes.isNotEmpty, isTrue);
      expect(excelBytes.length, greaterThan(10000));
    });
  });

  group('Track 2 - Reporting Actions: Disk Export Handlers', () {
    final testTransactions = [
      {
        'id': 1,
        'receipt_number': 'REC-TEST-01',
        'created_at': '2026-10-16T11:00:00Z',
        'itemCount': 2,
        'payment_method': 'Cash',
        'total_amount': 180.00,
        'status': 'Completed',
      },
    ];

    final testLogs = [
      {
        'id': 1,
        'timestamp': '2026-10-16T11:00:00Z',
        'username': 'admin',
        'role': 'admin',
        'module': 'TEST',
        'action': 'EXPORT',
        'status': 'SUCCESS',
        'description': 'Export test entry',
      },
    ];

    test('exportToPDF and exportToExcel write non-empty files to disk', () async {
      final pdfFile = await ExportService.exportToPDF(testTransactions);
      expect(pdfFile, isNotNull);
      expect(await pdfFile!.exists(), isTrue);
      expect(await pdfFile.length(), greaterThan(0));
      await pdfFile.delete();

      final excelFile = await ExportService.exportToExcel(testTransactions);
      expect(excelFile, isNotNull);
      expect(await excelFile!.exists(), isTrue);
      expect(await excelFile.length(), greaterThan(0));
      await excelFile.delete();
    });

    test('exportLogsToPDF and exportLogsToExcel write non-empty files to disk', () async {
      final pdfFile = await ExportService.exportLogsToPDF(testLogs);
      expect(pdfFile, isNotNull);
      expect(await pdfFile!.exists(), isTrue);
      expect(await pdfFile.length(), greaterThan(0));
      await pdfFile.delete();

      final excelFile = await ExportService.exportLogsToExcel(testLogs);
      expect(excelFile, isNotNull);
      expect(await excelFile!.exists(), isTrue);
      expect(await excelFile.length(), greaterThan(0));
      await excelFile.delete();
    });
  });
}
