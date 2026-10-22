import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';


void main() {
  group('SecurityUtils', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('hashPassword returns non-null string with iterations:salt:hash format', () {
      final hash = SecurityUtils.hashPassword('password123', null, 1000);
      expect(hash, isNotNull);
      final parts = hash.split(':');
      expect(parts.length, equals(3));
      expect(parts[0], equals('1000'));
      expect(parts[1].isNotEmpty, isTrue);
      expect(parts[2].isNotEmpty, isTrue);
    });

    test('verifyPassword returns true for correct password, false for wrong', () {
      final hash = SecurityUtils.hashPassword('password123');
      expect(SecurityUtils.verifyPassword('password123', hash), isTrue);
      expect(SecurityUtils.verifyPassword('wrongpassword', hash), isFalse);
    });

    test('verifyPassword returns false on malformed hash input', () {
      expect(SecurityUtils.verifyPassword('password123', 'malformed_hash_no_colon'), isFalse);
      expect(SecurityUtils.verifyPassword('password123', ''), isFalse);
    });

    test('encryptFaceEncoding and decryptFaceEncoding roundtrip preserves data', () async {
      const plainText = '{"features":[0.1,0.2,0.3],"version":1}';
      
      final cipherText = await SecurityUtils.encryptFaceEncoding(plainText);
      expect(cipherText, isNot(equals(plainText)));
      expect(cipherText, isNotEmpty);
      
      final decryptedText = await SecurityUtils.decryptFaceEncoding(cipherText);
      expect(decryptedText, equals(plainText));
    });
  });
}
