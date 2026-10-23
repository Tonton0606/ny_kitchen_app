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

    test('isPasswordValid and validatePassword enforce 8+ chars with letters and digits', () {
      expect(SecurityUtils.isPasswordValid('short1'), isFalse);
      expect(SecurityUtils.isPasswordValid('alllettershere'), isFalse);
      expect(SecurityUtils.isPasswordValid('12345678'), isFalse);
      expect(SecurityUtils.isPasswordValid('ValidPass1'), isTrue);

      expect(SecurityUtils.validatePassword('weak'), equals(SecurityUtils.passwordPolicyMessage));
      expect(SecurityUtils.validatePassword('ValidPass1'), isNull);
    });
  });
}
