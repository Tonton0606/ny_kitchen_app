import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

/// One-way sales replication. Never downloads accounts or overwrites local sales.
class BackendSyncService {
  BackendSyncService({
    required this.baseUrl,
    required String token,
    http.Client? client,
    Future<Database> Function()? database,
  }) : _token = token,
       _client = client ?? http.Client(),
       _database = database ?? (() => DatabaseHelper.instance.database) {
    final local = baseUrl.host == '127.0.0.1' || baseUrl.host == 'localhost';
    if ((baseUrl.scheme != 'https' && !(local && baseUrl.scheme == 'http')) ||
        baseUrl.host.isEmpty ||
        baseUrl.userInfo.isNotEmpty ||
        baseUrl.hasQuery ||
        baseUrl.hasFragment ||
        (baseUrl.path.isNotEmpty && baseUrl.path != '/')) {
      throw ArgumentError('Use an HTTPS backend origin without a path.');
    }
    if (token.length < 32) {
      throw ArgumentError('A provisioned token is required.');
    }
  }

  static BackendSyncService? instance;
  final Uri baseUrl;
  final String _token;
  final http.Client _client;
  final Future<Database> Function() _database;
  final ValueNotifier<String> status = ValueNotifier('Not synchronized');
  Future<bool>? _activeSync;

  static int _cents(Object? value) {
    if (value is! num || !value.isFinite || value < 0) {
      throw const FormatException('Invalid monetary value');
    }
    return (value * 100).round();
  }

  /// Explicit allowlist excludes user identities, password hashes and biometrics.
  static Map<String, Object?> salePayload(
    Map<String, Object?> sale,
    List<Map<String, Object?>> items,
  ) => {
    'local_id': sale['id'],
    'receipt_number': sale['receipt_number'],
    'order_type': sale['order_type'] ?? 'dine_in',
    'packaging_fee_cents': _cents(sale['packaging_fee'] ?? 0),
    'total_cents': _cents(sale['total_amount']),
    'discount_cents': _cents(sale['discount'] ?? 0),
    'payment_method': sale['payment_method'],
    'status': sale['status'],
    'created_at': sale['created_at'],
    'items': items
        .map(
          (item) => <String, Object?>{
            'food_name': item['food_name'],
            'quantity': item['quantity'],
            'unit_price_cents': _cents(item['food_price']),
            'subtotal_cents': _cents(item['subtotal']),
          },
        )
        .toList(),
  };

  Future<bool> sync() {
    final activeSync = _activeSync;
    if (activeSync != null) return activeSync;

    late final Future<bool> trackedSync;
    trackedSync = _runSync().whenComplete(() {
      if (identical(_activeSync, trackedSync)) _activeSync = null;
    });
    _activeSync = trackedSync;
    return trackedSync;
  }

  Future<bool> _runSync() async {
    status.value = 'Synchronizing';
    try {
      final db = await _database();
      // A token rotation or different destination triggers an idempotent replay.
      final destination = sha256
          .convert(utf8.encode('$baseUrl|$_token'))
          .toString();
      var after = 0;
      var sent = 0;
      while (true) {
        final rows = await db.transaction((txn) async {
          final sales = await txn.query(
            'transactions',
            where: 'id > ?',
            whereArgs: [after],
            orderBy: 'id',
            limit: 50,
          );
          final result = <Map<String, Object?>>[];
          for (final sale in sales) {
            final items = await txn.query(
              'transaction_items',
              where: 'transaction_id = ?',
              whereArgs: [sale['id']],
              orderBy: 'id',
            );
            result.add(salePayload(sale, items));
          }
          return result;
        });
        if (rows.isEmpty) break;
        after = rows.last['local_id'] as int;
        for (final sale in rows) {
          final key = 'backend_sync:$destination:${sale['local_id']}';
          final digest = sha256
              .convert(utf8.encode(jsonEncode(sale)))
              .toString();
          final previous = await db.query(
            'app_settings',
            columns: ['value'],
            where: 'key = ?',
            whereArgs: [key],
          );
          if (previous.isNotEmpty && previous.first['value'] == digest) {
            continue;
          }
          // Single-record batches bound retries and checkpoint each accepted sale.
          final request =
              http.Request('POST', baseUrl.resolve('/v1/sales/sync'))
                ..followRedirects = false
                ..headers.addAll({
                  'Authorization': 'Bearer $_token',
                  'Content-Type': 'application/json',
                })
                ..body = jsonEncode({
                  'sales': [sale],
                });
          if (utf8.encode(request.body).length > 262144) {
            throw const FormatException('Sale exceeds synchronization limit');
          }
          final response = await _client
              .send(request)
              .then(http.Response.fromStream)
              .timeout(const Duration(seconds: 8));
          if (response.statusCode != 200) {
            status.value =
                'Sync rejected (${response.statusCode}); local data retained';
            return false;
          }
          final result = jsonDecode(response.body);
          if (result is! Map || result['accepted'] != 1) {
            throw const FormatException(
              'Invalid synchronization acknowledgement',
            );
          }
          await db.insert('app_settings', {
            'key': key,
            'value': digest,
            'updated_at': DateTime.now().toIso8601String(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          // Keep cycles below the backend per-minute rate limit.
          if (++sent >= 40) {
            status.value = 'Batch synchronized; remaining sales queued';
            return false;
          }
        }
      }
      status.value = 'Sales synchronized';
      return true;
    } catch (_) {
      status.value = 'Sync unavailable; local sales retained for retry';
      return false;
    }
  }
}
