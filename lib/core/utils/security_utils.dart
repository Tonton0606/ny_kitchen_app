import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class SecurityUtils {
  static const int _iterations = 10000;
  static const int _keyLength = 32;

  /// Generates a random secure salt
  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64.encode(bytes);
  }

  /// Hashes a password using PBKDF2-HMAC-SHA256.
  /// If [salt] is provided, it hashes the password with that salt.
  /// If not, it generates a new salt and returns 'salt:hash'.
  static String hashPassword(String password, [String? salt]) {
    final actualSalt = salt ?? generateSalt();
    final saltBytes = utf8.encode(actualSalt);
    final passwordBytes = utf8.encode(password);

    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(saltBytes, _iterations, _keyLength));
    
    final hashBytes = derivator.process(passwordBytes);
    final hashString = base64.encode(hashBytes);

    return '$actualSalt:$hashString';
  }

  /// Verifies a password against a stored 'salt:hash' string
  static bool verifyPassword(String password, String storedHash) {
    try {
      final parts = storedHash.split(':');
      if (parts.length != 2) return false;
      
      final salt = parts[0];
      final newHash = hashPassword(password, salt);
      return newHash == storedHash;
    } catch (_) {
      return false; // Fallback fail
    }
  }
}
