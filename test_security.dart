import 'dart:convert';
import 'lib/core/utils/security_utils.dart';

void main() {
  final jsonString = '[0.1, 0.2, -0.3, 0.4]';
  final encrypted = SecurityUtils.encryptFaceEncoding(jsonString);
  print('Encrypted: $encrypted');
  final decrypted = SecurityUtils.decryptFaceEncoding(encrypted);
  print('Decrypted: $decrypted');
  if (jsonString == decrypted) {
    print('SUCCESS');
  } else {
    print('FAILURE');
  }
}
