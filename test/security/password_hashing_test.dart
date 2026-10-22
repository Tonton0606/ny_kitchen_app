import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';
import 'dart:convert';

void main() {
  group('SecurityUtils Password Hashing (Task B1 - 600,000 Iterations & Metadata)', () {
    test('PBKDF2 output is deterministic with same salt and iterations', () {
      const password = 'TestPassword123!';
      const salt = 'TestSaltBase64==';

      // Use lower iterations for fast determinism check
      final hash1 = SecurityUtils.hashPassword(password, salt, 1000);
      final hash2 = SecurityUtils.hashPassword(password, salt, 1000);

      expect(hash1, equals(hash2));
      expect(SecurityUtils.verifyPassword(password, hash1), isTrue);
    });

    test('Different salts produce different hashes for same password', () {
      const password = 'TestPassword123!';
      const salt1 = 'SaltOne=';
      const salt2 = 'SaltTwo=';

      final hash1 = SecurityUtils.hashPassword(password, salt1, 1000);
      final hash2 = SecurityUtils.hashPassword(password, salt2, 1000);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Modern hash format is iterations:salt:hash with metadata (base64)', () {
      const password = 'TestPassword123!';
      final hash = SecurityUtils.hashPassword(password, null, 1000);

      final parts = hash.split(':');
      expect(parts.length, equals(3), reason: 'Must contain iterations:salt:hash');
      expect(int.parse(parts[0]), equals(1000));

      // Verify base64 encoding of salt and hash
      expect(() => base64.decode(parts[1]), returnsNormally);
      expect(() => base64.decode(parts[2]), returnsNormally);
    });

    test('Default hash generation uses 600,000 target iterations', () {
      expect(SecurityUtils.targetIterations, equals(600000));
      expect(SecurityUtils.defaultIterations, equals(600000));
    });

    test('Backward compatibility: Legacy 2-part hash (10,000 iter) verifies successfully', () {
      const password = 'password';
      // Known RFC 6070 vector for password="password", salt="salt", iterations=10000, keyLen=32
      const legacyHash = 'salt:XsArkaS1nG9Z3V++TKZJ7OT6hWjNuLo2z0FCbogFUis=';

      expect(SecurityUtils.verifyPassword(password, legacyHash), isTrue);
      expect(SecurityUtils.verifyPassword('wrongpassword', legacyHash), isFalse);
    });

    test('needsRehash flags legacy hashes and under-iterated hashes for upgrade', () {
      const legacyHash = 'salt:XsArkaS1nG9Z3V++TKZJ7OT6hWjNuLo2z0FCbogFUis=';
      const underIteratedHash = '50000:salt:someHashBase64==';
      const modernHash = '600000:salt:someHashBase64==';

      expect(SecurityUtils.needsRehash(legacyHash), isTrue,
          reason: 'Legacy 2-part hashes must be flagged for rehash');
      expect(SecurityUtils.needsRehash(underIteratedHash), isTrue,
          reason: 'Hashes with < 600,000 iterations must be flagged for rehash');
      expect(SecurityUtils.needsRehash(modernHash), isFalse,
          reason: 'Hashes meeting 600,000 target must not require rehash');
    });

    test('verifyPassword handles malformed and invalid strings safely', () {
      expect(SecurityUtils.verifyPassword('password', ''), isFalse);
      expect(SecurityUtils.verifyPassword('password', 'invalid_no_colon'), isFalse);
      expect(SecurityUtils.verifyPassword('password', 'notanumber:salt:hash'), isFalse);
      expect(SecurityUtils.verifyPassword('password', '1:2:3:4:extra_parts'), isFalse);
    });

    test('verifyPassword handles both 2-part and 3-part hashes seamlessly', () {
      const password = 'password';
      const salt = 'salt';
      const expectedHash = 'XsArkaS1nG9Z3V++TKZJ7OT6hWjNuLo2z0FCbogFUis=';

      // 2-part format
      expect(SecurityUtils.verifyPassword(password, '$salt:$expectedHash'), isTrue);

      // 3-part format with explicit iteration count
      expect(SecurityUtils.verifyPassword(password, '10000:$salt:$expectedHash'), isTrue);

      // Incorrect password fails on both formats
      expect(SecurityUtils.verifyPassword('wrongPassword', '$salt:$expectedHash'), isFalse);
      expect(SecurityUtils.verifyPassword('wrongPassword', '10000:$salt:$expectedHash'), isFalse);

      // Malformed hash fails safely without crashing
      expect(SecurityUtils.verifyPassword(password, 'invalid_hash'), isFalse);
    });
  });
}
