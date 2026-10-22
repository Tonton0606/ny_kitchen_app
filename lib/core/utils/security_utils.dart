import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
          ..init(Pbkdf2Parameters(saltBytes, iter, _keyLength));
        final hashBytes = derivator.process(passwordBytes);
        final computedHash = base64.encode(hashBytes);

        return computedHash == expectedHash;
      } else if (parts.length == 2) {
        final salt = parts[0];
        final expectedHash = parts[1];

        final saltBytes = utf8.encode(salt);
        final passwordBytes = utf8.encode(password);
        final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
          ..init(Pbkdf2Parameters(saltBytes, _iterations, _keyLength));
        final hashBytes = derivator.process(passwordBytes);
        final computedHash = base64.encode(hashBytes);

        return computedHash == expectedHash;
      }
      return false;
    } catch (_) {
      return false; // Fallback fail
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

  static const String _keyStorageKey = 'ny_kitchen_aes_key';
  static const String _ivStorageKey = 'ny_kitchen_aes_iv';
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static Future<Map<String, Uint8List>> _getEncryptionKeys() async {
    String? storedKeyStr = await _secureStorage.read(key: _keyStorageKey);
    String? storedIvStr = await _secureStorage.read(key: _ivStorageKey);

    Uint8List keyBytes;
    Uint8List ivBytes;

    if (storedKeyStr == null || storedIvStr == null) {
      // Generate new secure random keys
      final random = Random.secure();
      keyBytes = Uint8List(32);
      ivBytes = Uint8List(16);
      for (int i = 0; i < 32; i++) {
        keyBytes[i] = random.nextInt(256);
      }
      for (int i = 0; i < 16; i++) {
        ivBytes[i] = random.nextInt(256);
      }

      // Save them securely
      await _secureStorage.write(key: _keyStorageKey, value: base64.encode(keyBytes));
      await _secureStorage.write(key: _ivStorageKey, value: base64.encode(ivBytes));
    } else {
      keyBytes = base64.decode(storedKeyStr);
      ivBytes = base64.decode(storedIvStr);
    }

    return {'key': keyBytes, 'iv': ivBytes};
  }

  /// Encrypts a string (e.g. face encoding JSON) using AES-CBC with PKCS7 padding
  static Future<String> encryptFaceEncoding(String plainText) async {
    final keys = await _getEncryptionKeys();
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(keys['key']!), keys['iv']!));

    final plainTextBytes = utf8.encode(plainText);
    
    // Add PKCS7 padding
    final paddingLength = 16 - (plainTextBytes.length % 16);
    final paddedBytes = Uint8List(plainTextBytes.length + paddingLength);
    paddedBytes.setAll(0, plainTextBytes);
    for (int i = 0; i < paddingLength; i++) {
      paddedBytes[plainTextBytes.length + i] = paddingLength;
    }

    final cipherText = Uint8List(paddedBytes.length);
    for (int offset = 0; offset < paddedBytes.length; offset += 16) {
      cipher.processBlock(paddedBytes, offset, cipherText, offset);
    }
    
    return base64.encode(cipherText);
  }

  /// Decrypts a base64 encoded AES-CBC cipher text
  static Future<String> decryptFaceEncoding(String cipherTextBase64) async {
    try {
      final keys = await _getEncryptionKeys();
      final cipher = CBCBlockCipher(AESEngine())
        ..init(false, ParametersWithIV(KeyParameter(keys['key']!), keys['iv']!));
        
      final cipherText = base64.decode(cipherTextBase64);
      final paddedBytes = Uint8List(cipherText.length);
      
      for (int offset = 0; offset < cipherText.length; offset += 16) {
        cipher.processBlock(cipherText, offset, paddedBytes, offset);
      }
      
      // Remove padding
      final paddingLength = paddedBytes.last;
      if (paddingLength > 0 && paddingLength <= 16) {
        return utf8.decode(paddedBytes.sublist(0, paddedBytes.length - paddingLength));
      }
      return utf8.decode(paddedBytes);
    } catch (e) {
      // Fallback
      return cipherTextBase64;
    }
  }
}
