import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'dart:convert';

void main() {
  group('SecurityUtils Password Hashing', () {
    test('PBKDF2 output is deterministic with same salt', () {
      const password = 'TestPassword123!';
      const salt = 'TestSaltBase64==';

      final hash1 = SecurityUtils.hashPassword(password, salt);
      final hash2 = SecurityUtils.hashPassword(password, salt);

      expect(hash1, equals(hash2));
      expect(SecurityUtils.verifyPassword(password, hash1), isTrue);
    });

    test('Different salts produce different hashes for same password', () {
      const password = 'TestPassword123!';
      const salt1 = 'SaltOne=';
      const salt2 = 'SaltTwo=';

      final hash1 = SecurityUtils.hashPassword(password, salt1);
      final hash2 = SecurityUtils.hashPassword(password, salt2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Hash format is salt:hash (base64)', () {
      const password = 'TestPassword123!';
      final hash = SecurityUtils.hashPassword(password);
      
      final parts = hash.split(':');
      expect(parts.length, equals(2));
      
      // Verify base64 encoding (if it decodes without throwing, it's valid base64)
      expect(() => base64.decode(parts[0]), returnsNormally);
      expect(() => base64.decode(parts[1]), returnsNormally);
    });

    test('Verify iteration count is 10000 by checking against known hash', () {
      const password = 'password';
      const salt = 'salt';
      
      final result = SecurityUtils.hashPassword(password, salt);
      
      final parts = result.split(':');
      expect(parts[0], equals('salt'));
      
      // Known hash for password="password", salt="salt", iterations=10000, keyLen=32
      expect(parts[1], equals('T98UqS8m43i9Fq39O31/Z42k/b4V/zJ1+r3VjF5L3z0='));
    });
  });
}
