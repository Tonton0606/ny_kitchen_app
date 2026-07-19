import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityUtils {
  /// Hashes a password using SHA-256
  static String hashPassword(String password) {
    // In a production app, we should use a unique salt per user. 
    // For this scope, a global salt combined with SHA256 is a basic improvement over plaintext.
    const salt = 'ny_kitchen_secure_salt_2026';
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
