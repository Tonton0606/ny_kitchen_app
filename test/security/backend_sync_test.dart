import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ny_kitchen_app/core/services/backend_sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  const token = 'synthetic-device-token-for-testing-only';
  setUp(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE transactions(id INTEGER PRIMARY KEY, receipt_number TEXT, total_amount REAL, discount REAL, payment_method TEXT, status TEXT, created_at TEXT)',
    );
    await db.execute(
      'CREATE TABLE transaction_items(id INTEGER PRIMARY KEY, transaction_id INTEGER, food_name TEXT, food_price REAL, quantity INTEGER, subtotal REAL)',
    );
    await db.execute(
      'CREATE TABLE app_settings(key TEXT PRIMARY KEY, value TEXT, updated_at TEXT)',
    );
    await db.insert('transactions', {
      'id': 1,
      'receipt_number': 'DEMO-1',
      'total_amount': 100.0,
      'discount': 0.0,
      'payment_method': 'cash',
      'status': 'Served',
      'created_at': '2026-10-22T10:00:00',
    });
    await db.insert('transaction_items', {
      'id': 1,
      'transaction_id': 1,
      'food_name': 'Meal',
      'food_price': 50.0,
      'quantity': 2,
      'subtotal': 100.0,
    });
  });
  tearDown(() async => db.close());

  test('HTTPS required outside loopback', () {
    expect(
      () => BackendSyncService(
        baseUrl: Uri.parse('http://192.168.56.10'),
        token: token,
      ),
      throwsArgumentError,
    );
    expect(
      () => BackendSyncService(
        baseUrl: Uri.parse('https://host/path'),
        token: token,
      ),
      throwsArgumentError,
    );
  });

  test('Successful ack checkpoints; changes send a new revision', () async {
    var requests = 0;
    final service = BackendSyncService(
      baseUrl: Uri.parse('https://pos.example'),
      token: token,
      database: () async => db,
      client: MockClient((request) async {
        requests++;
        expect(request.headers['Authorization'], 'Bearer $token');
        expect(request.followRedirects, isFalse);
        final sale = (jsonDecode(request.body)['sales'] as List).single as Map;
        expect(sale['total_cents'], 10000);
        expect(sale.containsKey('user_id'), isFalse);
        return http.Response('{"accepted":1,"new_revisions":1}', 200);
      }),
    );
    await service.sync();
    await service.sync();
    expect(requests, 1);
    await db.update('transactions', {'status': 'Refunded'});
    await service.sync();
    expect(requests, 2);
    expect(service.status.value, 'Sales synchronized');
  });

  test(
    'Offline failure preserves local data and retries without checkpoint',
    () async {
      var online = false;
      final service = BackendSyncService(
        baseUrl: Uri.parse('https://pos.example'),
        token: token,
        database: () async => db,
        client: MockClient((request) async {
          if (!online) throw http.ClientException('offline');
          return http.Response('{"accepted":1,"new_revisions":1}', 200);
        }),
      );
      await service.sync();
      expect(await db.query('app_settings'), isEmpty);
      expect((await db.query('transactions')).length, 1);
      online = true;
      await service.sync();
      expect((await db.query('app_settings')).length, 1);
    },
  );

  test('403 and invalid acknowledgement do not lose pending sales', () async {
    for (final response in [
      http.Response('{}', 403),
      http.Response('{"accepted":0}', 200),
    ]) {
      final service = BackendSyncService(
        baseUrl: Uri.parse('https://pos.example'),
        token: token,
        database: () async => db,
        client: MockClient((_) async => response),
      );
      await service.sync();
      expect(await db.query('app_settings'), isEmpty);
      expect((await db.query('transactions')).length, 1);
    }
  });
}
