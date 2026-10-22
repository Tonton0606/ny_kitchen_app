import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  /// Encrypts a string (e.g. face encoding JSON) using AES-256-GCM with a fresh 12-byte random nonce (Task B2).
  /// Output format: `v2:<nonce_base64>:<ciphertext_tag_base64>`
  static Future<String> encryptFaceEncoding(String plainText, [Uint8List? explicitKey]) async {
    final key = explicitKey ?? (await _getEncryptionKeys())['key']!;
    
    // Generate fresh 12-byte random nonce per encryption (never reuse nonces)
    final random = Random.secure();
    final nonce = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      nonce[i] = random.nextInt(256);
    }

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));

    final plainTextBytes = utf8.encode(plainText);
    final cipherBytes = cipher.process(Uint8List.fromList(plainTextBytes));

    return 'v2:${base64.encode(nonce)}:${base64.encode(cipherBytes)}';
  }

  /// Checks if stored ciphertext is in legacy format (lacks 'v2:' prefix).
  static bool isLegacyFaceEncoding(String cipherText) {
    return !cipherText.startsWith('v2:');
  }

  /// Decrypts face encoding ciphertext.
  /// Supports:
  /// - Version 2 (AES-GCM authenticated): `v2:<nonce>:<ciphertext_tag>`
  /// - Legacy (AES-CBC unversioned): base64 encoded CBC ciphertext
  /// Throws FormatException if authentication tag check fails or data is tampered.
  static Future<String> decryptFaceEncoding(String cipherText, [Uint8List? explicitKey]) async {
    final keys = await _getEncryptionKeys();
    final key = explicitKey ?? keys['key']!;

    if (cipherText.startsWith('v2:')) {
      final parts = cipherText.split(':');
      if (parts.length != 3) {
        throw const FormatException('Invalid v2 face encoding format');
      }

      final nonce = base64.decode(parts[1]);
      if (nonce.length != 12) {
        throw const FormatException('Invalid nonce length: must be 12 bytes');
      }
      final cipherBytes = base64.decode(parts[2]);

      try {
        final decipher = GCMBlockCipher(AESEngine())
          ..init(false, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
        final decryptedBytes = decipher.process(cipherBytes);
        return utf8.decode(decryptedBytes);
      } catch (e) {
        throw FormatException('Face encoding decryption failed: authentication tag mismatch or corrupted data ($e)');
      }
    } else {
      // Legacy AES-CBC fallback
      try {
        final iv = keys['iv']!;
        final cipher = CBCBlockCipher(AESEngine())
          ..init(false, ParametersWithIV(KeyParameter(key), iv));

        final cipherBytes = base64.decode(cipherText);
        final paddedBytes = Uint8List(cipherBytes.length);

        for (int offset = 0; offset < cipherBytes.length; offset += 16) {
          cipher.processBlock(cipherBytes, offset, paddedBytes, offset);
        }

        final paddingLength = paddedBytes.last;
        if (paddingLength > 0 && paddingLength <= 16) {
          return utf8.decode(paddedBytes.sublist(0, paddedBytes.length - paddingLength));
        }
        return utf8.decode(paddedBytes);
      } catch (e) {
        throw FormatException('Legacy face encoding decryption failed: $e');
      }
    }
  }

  /// Helper for testing: Encrypts using the legacy AES-CBC algorithm
  static Future<String> encryptLegacyFaceEncodingForTesting(String plainText, [Uint8List? explicitKey]) async {
    final keys = await _getEncryptionKeys();
    final key = explicitKey ?? keys['key']!;
    final iv = keys['iv']!;

    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(key), iv));

    final plainTextBytes = utf8.encode(plainText);
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
}
