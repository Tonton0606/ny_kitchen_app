import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';

void main() {
  group('SecurityUtils Password Policy Enforcement', () {
    test('Password policy message is informative and present', () {
      expect(SecurityUtils.passwordPolicyMessage, isNotEmpty);
      expect(SecurityUtils.passwordPolicyMessage.toLowerCase(), contains('8 characters'));
      expect(SecurityUtils.passwordPolicyMessage.toLowerCase(), contains('letter'));
      expect(SecurityUtils.passwordPolicyMessage.toLowerCase(), contains('number'));
    });

    test('Valid passwords pass policy check', () {
      expect(SecurityUtils.isPasswordValid('Password123'), isTrue);
      expect(SecurityUtils.isPasswordValid('Admin2026!'), isTrue);
      expect(SecurityUtils.isPasswordValid('cashier1'), isTrue);
      expect(SecurityUtils.isPasswordValid('a1b2c3d4e5'), isTrue);
      expect(SecurityUtils.isPasswordValid('VeryStrongPassword99#'), isTrue);
    });

    test('Passwords shorter than 8 characters fail', () {
      expect(SecurityUtils.isPasswordValid('Pass1'), isFalse);
      expect(SecurityUtils.isPasswordValid('Abc1234'), isFalse);
      expect(SecurityUtils.isPasswordValid('a1'), isFalse);
      expect(SecurityUtils.isPasswordValid(''), isFalse);
    });

    test('Passwords without digits fail', () {
      expect(SecurityUtils.isPasswordValid('PasswordOnly'), isFalse);
      expect(SecurityUtils.isPasswordValid('abcdefghijk'), isFalse);
      expect(SecurityUtils.isPasswordValid('NoNumbersHere!'), isFalse);
    });

    test('Passwords without letters fail', () {
      expect(SecurityUtils.isPasswordValid('12345678'), isFalse);
      expect(SecurityUtils.isPasswordValid('1234567890'), isFalse);
      expect(SecurityUtils.isPasswordValid('12345678!@#'), isFalse);
    });
  });
}
