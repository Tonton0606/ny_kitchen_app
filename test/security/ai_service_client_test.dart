import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/services/ai_service_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('A3 - AI Service Shared Key Authentication', () {
    test('AIServiceClient must expose and attach serviceKey header from config', () {
      final client = AIServiceClient(serviceKey: 'test-secret-key-123');
      expect(client.serviceKey, equals('test-secret-key-123'));

      final headers = client.headers;
      expect(headers.containsKey('X-Service-Key'), isTrue,
          reason: 'Must include X-Service-Key header');
      expect(headers['X-Service-Key'], equals('test-secret-key-123'));
    });

    test('AIServiceClient must not have a hardcoded fallback service key', () {
      final client = AIServiceClient(serviceKey: '');
      expect(client.headers.containsKey('X-Service-Key'), isFalse,
          reason: 'Must not use hardcoded secret fallback');
    });
  });
}
