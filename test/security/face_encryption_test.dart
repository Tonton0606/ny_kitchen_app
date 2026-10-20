import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/database/database_helper.dart';
import 'package:ny_kitchen_app/core/database/repositories/user_repository.dart';
import 'package:ny_kitchen_app/core/services/sync_service.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late UserRepository userRepository;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    FlutterSecureStorage.setMockInitialValues({});
  });

  setUp(() async {
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              full_name TEXT NOT NULL,
              username TEXT UNIQUE NOT NULL,
              password_hash TEXT NOT NULL,
              role TEXT NOT NULL,
              status TEXT NOT NULL,
              last_login TEXT,
              failed_login_count INTEGER DEFAULT 0,
              must_change_password INTEGER DEFAULT 0,
              face_encoding TEXT,
              created_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE activity_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              username TEXT,
              role TEXT,
              module TEXT NOT NULL,
              action TEXT NOT NULL,
              status TEXT NOT NULL,
              description TEXT,
              metadata TEXT,
              timestamp TEXT NOT NULL
            )
          ''');
        },
      ),
    );

    DatabaseHelper.setMockDatabase(db);
    userRepository = UserRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('B2 - AES-GCM Face Encoding Encryption & Migration', () {
    const plainEncoding = '{"features":[0.123, -0.456, 0.789, 0.012], "version":1}';

    test('New GCM round trip preserves data and outputs v2 format with 12-byte nonce', () async {
      final cipher1 = await SecurityUtils.encryptFaceEncoding(plainEncoding);
      expect(cipher1.startsWith('v2:'), isTrue, reason: 'Must use v2: prefix for GCM');

      final parts = cipher1.split(':');
      expect(parts.length, equals(3), reason: 'Format must be v2:nonce:ciphertext');
      final nonceBytes = base64.decode(parts[1]);
      expect(nonceBytes.length, equals(12), reason: 'GCM nonce must be 12 bytes');

      final decrypted = await SecurityUtils.decryptFaceEncoding(cipher1);
      expect(decrypted, equals(plainEncoding));

      // Test nonce uniqueness (never reuse nonces)
      final cipher2 = await SecurityUtils.encryptFaceEncoding(plainEncoding);
      final parts2 = cipher2.split(':');
      expect(parts[1], isNot(equals(parts2[1])), reason: 'Nonces must never be reused');
      expect(cipher1, isNot(equals(cipher2)));
    });

    test('Legacy CBC record still decrypts and is detected as legacy', () async {
      final legacyCipher = await SecurityUtils.encryptLegacyFaceEncodingForTesting(plainEncoding);
      expect(SecurityUtils.isLegacyFaceEncoding(legacyCipher), isTrue);

      final decrypted = await SecurityUtils.decryptFaceEncoding(legacyCipher);
      expect(decrypted, equals(plainEncoding));
    });

    test('Legacy CBC record is transparently upgraded to GCM in SQLite on read', () async {
      final legacyCipher = await SecurityUtils.encryptLegacyFaceEncodingForTesting(plainEncoding);
      const username = 'face_user_migration';
      final now = DateTime.now().toIso8601String();

      await db.insert('users', {
        'full_name': 'Face User',
        'username': username,
        'password_hash': 'dummy_hash',
        'role': 'cashier',
        'status': 'active',
        'face_encoding': legacyCipher,
        'created_at': now,
      });

      // 1. Read users via repository
      final users = await userRepository.getUsersWithFaceEncoding();
      expect(users.isNotEmpty, isTrue);
      final matched = users.firstWhere((u) => u['username'] == username);
      expect(matched['face_encoding'], equals(plainEncoding),
          reason: 'Plain face encoding should be returned to caller');

      // 2. Inspect direct database record to verify transparent migration to v2 GCM
      final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
      final storedCipher = rows.first['face_encoding'] as String;
      expect(storedCipher.startsWith('v2:'), isTrue,
          reason: 'Database record must be transparently upgraded to v2 GCM on read');
      expect(SecurityUtils.isLegacyFaceEncoding(storedCipher), isFalse);

      // 3. Subsequent reads decrypt the upgraded GCM record seamlessly
      final usersAfter = await userRepository.getUsersWithFaceEncoding();
      final matchedAfter = usersAfter.firstWhere((u) => u['username'] == username);
      expect(matchedAfter['face_encoding'], equals(plainEncoding));
    });

    test('Tampered ciphertext fails authentication', () async {
      final validCipher = await SecurityUtils.encryptFaceEncoding(plainEncoding);
      final parts = validCipher.split(':');
      final cipherBytes = base64.decode(parts[2]);

      // Flip the last byte (tamper with authentication tag or ciphertext)
      cipherBytes[cipherBytes.length - 1] ^= 0xFF;
      final tamperedCipher = 'v2:${parts[1]}:${base64.encode(cipherBytes)}';

      expect(
        () async => await SecurityUtils.decryptFaceEncoding(tamperedCipher),
        throwsA(isA<FormatException>()),
        reason: 'Tampered ciphertext must fail authentication and throw FormatException',
      );
    });

    test('Wrong key fails authentication', () async {
      final random = Random.secure();
      final keyA = Uint8List(32);
      final keyB = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        keyA[i] = random.nextInt(256);
        keyB[i] = random.nextInt(256);
      }
      // Ensure keys are distinct
      keyB[0] = keyA[0] ^ 0xFF;

      final cipherWithKeyA = await SecurityUtils.encryptFaceEncoding(plainEncoding, keyA);

      expect(
        () async => await SecurityUtils.decryptFaceEncoding(cipherWithKeyA, keyB),
        throwsA(isA<FormatException>()),
        reason: 'Decrypting with a different key must fail authentication',
      );
    });

    test('Failed face encoding decryption sets in-memory face_encoding to null without overwriting SQLite', () async {
      const corruptCipher = 'v2:aW52YWxpZE5vbmNl:Y29ycnVwdGVkQ2lwaGVyVGV4dA==';
      const username = 'corrupt_face_user';
      final now = DateTime.now().toIso8601String();

      await db.insert('users', {
        'full_name': 'Corrupt Face User',
        'username': username,
        'password_hash': 'dummy_hash',
        'role': 'cashier',
        'status': 'active',
        'face_encoding': corruptCipher,
        'created_at': now,
      });

      // 1. Read through UserRepository - should catch decryption failure and set in-memory value to null
      final users = await userRepository.getUsersWithFaceEncoding();
      final matched = users.firstWhere((u) => u['username'] == username);
      expect(matched['face_encoding'], isNull,
          reason: 'In-memory face_encoding must be null when decryption fails');

      // 2. Query SQLite directly - verify the raw database column was NOT overwritten with null
      final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
      expect(rows.first['face_encoding'], equals(corruptCipher),
          reason: 'Raw SQLite record must never be overwritten with null on decryption error');
    });

    test('SyncService strips face_encoding and password_hash when preparing user for cloud push', () {
      final localUser = {
        'id': 1,
        'username': 'admin',
        'full_name': 'Administrator',
        'role': 'admin',
        'status': 'active',
        'password_hash': '600000:salt:hash',
        'face_encoding': 'v2:nonce:cipher',
        'created_at': '2026-10-16T00:00:00Z',
      };

      final sanitized = SyncService.sanitizeUserForCloudSync(localUser);

      expect(sanitized.containsKey('face_encoding'), isFalse,
          reason: 'face_encoding must be stripped before cloud upload');
      expect(sanitized.containsKey('password_hash'), isFalse,
          reason: 'password_hash must be stripped before cloud upload');
      expect(sanitized['username'], equals('admin'));
      expect(sanitized['id'], equals(1));
    });

    test('SyncService preserves existing local face_encoding on cloud pull', () {
      final existingLocal = {
        'id': 1,
        'username': 'cashier1',
        'role': 'cashier',
        'password_hash': 'local_hash',
        'face_encoding': 'v2:local_nonce:local_cipher',
        'failed_login_count': 2,
      };

      // Case A: Cloud record has null face_encoding
      final cloudRecordNullFace = {
        'id': 1,
        'username': 'cashier1',
        'role': 'cashier',
        'face_encoding': null,
      };
      final mergedA = SyncService.mergePulledUserRecord(cloudRecordNullFace, existingLocal);
      expect(mergedA['face_encoding'], equals('v2:local_nonce:local_cipher'),
          reason: 'Existing local face_encoding must be kept when cloud has null');

      // Case B: Cloud record has different face_encoding
      final cloudRecordOtherFace = {
        'id': 1,
        'username': 'cashier1',
        'role': 'cashier',
        'face_encoding': 'v2:cloud_nonce:cloud_cipher',
      };
      final mergedB = SyncService.mergePulledUserRecord(cloudRecordOtherFace, existingLocal);
      expect(mergedB['face_encoding'], equals('v2:local_nonce:local_cipher'),
          reason: 'Existing local face_encoding must never be overwritten by cloud data');
    });

    test('SQLite integration: cloud user pull preserves existing local face_encoding in database', () async {
      const existingFace = 'v2:local_nonce:local_cipher';
      await db.insert('users', {
        'id': 99,
        'full_name': 'Sync Test User',
        'username': 'sync_user',
        'password_hash': 'local_password_hash',
        'role': 'cashier',
        'status': 'active',
        'face_encoding': existingFace,
        'failed_login_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      final incomingCloudRecord = {
        'id': 99,
        'full_name': 'Sync Test User (Updated in Cloud)',
        'username': 'sync_user',
        'role': 'cashier',
        'status': 'active',
        'face_encoding': null,
        'created_at': DateTime.now().toIso8601String(),
      };

      final existingRows = await db.query('users', where: 'id = ?', whereArgs: [99]);
      final merged = SyncService.mergePulledUserRecord(incomingCloudRecord, existingRows.first);

      await db.insert(
        'users',
        merged,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final updatedRows = await db.query('users', where: 'id = ?', whereArgs: [99]);
      expect(updatedRows.first['face_encoding'], equals(existingFace),
          reason: 'Local face_encoding in SQLite must remain preserved after cloud pull');
      expect(updatedRows.first['full_name'], equals('Sync Test User (Updated in Cloud)'));
    });
  });
}
