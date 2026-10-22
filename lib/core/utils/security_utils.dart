import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class SecurityUtils {
  static const int legacyIterations = 10000;
  static const int targetIterations = 600000;
  static int defaultIterations = targetIterations;
  static const int keyLength = 32;

  /// Generates a random secure salt
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  /// Hashes a password using PBKDF2-HMAC-SHA256 with per-record iteration metadata (Task B1).
  /// Output format: '$iterations:$salt:$hash'
  static String hashPassword(String password, [String? salt, int? iterations]) {
    final iter = iterations ?? defaultIterations;
    final actualSalt = salt ?? generateSalt();
    final saltBytes = utf8.encode(actualSalt);
    final passwordBytes = utf8.encode(password);

    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, iter, keyLength));
    
    final hashBytes = derivator.process(passwordBytes);
    final hashString = base64.encode(hashBytes);

    return '$iter:$actualSalt:$hashString';
  }

  /// Verifies a password against a stored hash string.
  /// Backward compatible:
  /// - Modern format with iteration metadata (3 parts): '$iterations:$salt:$hash'
  /// - Legacy format (2 parts): '$salt:$hash' (evaluated with 10,000 legacy iterations)
  static bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length == 3) {
        final iter = int.tryParse(parts[0]);
        if (iter == null || iter <= 0) return false;
        final salt = parts[1];
        final expectedHash = parts[2];

        final saltBytes = utf8.encode(salt);
        final passwordBytes = utf8.encode(password);
        final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
          ..init(Pbkdf2Parameters(saltBytes, iter, keyLength));
        final hashBytes = derivator.process(passwordBytes);
        final computedHash = base64.encode(hashBytes);

        return computedHash == expectedHash;
      } else if (parts.length == 2) {
        final salt = parts[0];
        final expectedHash = parts[1];

        final saltBytes = utf8.encode(salt);
        final passwordBytes = utf8.encode(password);
        final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
          ..init(Pbkdf2Parameters(saltBytes, legacyIterations, keyLength));
        final hashBytes = derivator.process(passwordBytes);
        final computedHash = base64.encode(hashBytes);

        return computedHash == expectedHash;
      }
      return false;
    } catch (_) {
      return false; // Fallback fail
    }
  }

  /// Checks if a stored password hash needs to be upgraded/re-hashed to the modern target iterations.
  /// Returns true for legacy 2-part hashes or hashes where iterations < targetIterations (600,000).
  static bool needsRehash(String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length == 2) return true; // Legacy format lacking iteration metadata
      if (parts.length == 3) {
        final iter = int.tryParse(parts[0]);
        if (iter == null || iter < targetIterations) return true;
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  // Password policy: minimum 8 characters, at least one letter and one number
  static const String passwordPolicyMessage = 'Password must be at least 8 characters long and include at least one letter and one number.';
  static bool isPasswordValid(String password) {
    if (password.length < 8) return false;
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    return hasLetter && hasDigit;
  }
}
