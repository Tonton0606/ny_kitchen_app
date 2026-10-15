import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('A1 - Environment & Secrets Protection', () {
    test('.gitignore must explicitly ignore .env file', () {
      final gitignoreFile = File('.gitignore');
      expect(gitignoreFile.existsSync(), isTrue, reason: '.gitignore must exist');

      final lines = gitignoreFile.readAsLinesSync().map((l) => l.trim()).toList();
      final hasDotEnv = lines.any((line) => line == '.env' || line == '/.env' || line == '**/.env');
      expect(hasDotEnv, isTrue, reason: '.gitignore must contain .env to prevent secret leakage');
    });

    test('.env.example must exist and contain placeholder keys without real secrets', () {
      final exampleFile = File('.env.example');
      expect(exampleFile.existsSync(), isTrue, reason: '.env.example must exist as a template');

      final content = exampleFile.readAsStringSync();
      expect(content.contains('SUPABASE_URL='), isTrue);
      expect(content.contains('SUPABASE_ANON_KEY='), isTrue);
      expect(content.contains('SUPABASE_DEVICE_SECRET='), isTrue);

      // Verify no actual JWT or real long secrets are in the example file
      expect(content.contains('eyJ'), isFalse, reason: 'Must not contain JWT credentials');
    });
  });
}
