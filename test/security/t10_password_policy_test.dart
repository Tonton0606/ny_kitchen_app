import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/utils/security_utils.dart';

void main() {
  group('T-10: Password Policy & Input Validation Security Tests', () {
    test('Password policy requires minimum 8 characters with letters and numbers', () {
      expect(SecurityUtils.passwordPolicyMessage, isNotEmpty);
      expect(SecurityUtils.passwordPolicyMessage.toLowerCase(), contains('8 characters'));
      expect(SecurityUtils.passwordPolicyMessage.toLowerCase(), contains('letter'));
      expect(SecurityUtils.passwordPolicyMessage.toLowerCase(), contains('number'));
    });

    test('Valid strong passwords pass policy checks', () {
      final validPasswords = [
        'Admin2026!',
        'NYKitchen#99',
        'c@shier123',
        'StrongPassword1',
        'ComplexPass999_xyz',
      ];

      for (final password in validPasswords) {
        expect(SecurityUtils.isPasswordValid(password), isTrue,
            reason: 'Password "$password" should be valid');
        expect(SecurityUtils.validatePassword(password), isNull,
            reason: 'Password "$password" should have no validation error');
      }
    });

    test('Rejects short passwords under 8 characters', () {
      final shortPasswords = ['', 'a', 'Ab1!', '1234567', 'Short1!'];

      for (final password in shortPasswords) {
        expect(SecurityUtils.isPasswordValid(password), isFalse,
            reason: 'Password "$password" should be rejected as too short');
        expect(SecurityUtils.validatePassword(password), isNotNull);
      }
    });

    test('Rejects passwords missing numbers or letters', () {
      final letterOnly = ['PasswordOnly', 'AdminAdmin', 'ValidLengthNoDigits!'];
      for (final p in letterOnly) {
        expect(SecurityUtils.isPasswordValid(p), isFalse,
            reason: 'Password "$p" without numbers should fail');
      }

      final digitOnly = ['12345678', '9876543210', '12345678!@#'];
      for (final p in digitOnly) {
        expect(SecurityUtils.isPasswordValid(p), isFalse,
            reason: 'Password "$p" without letters should fail');
      }
    });

    test('Rejects pure whitespace or edge control characters', () {
      expect(SecurityUtils.isPasswordValid('        '), isFalse);
      expect(SecurityUtils.isPasswordValid('\t\n\r  1a'), isFalse);
    });
  });
}
