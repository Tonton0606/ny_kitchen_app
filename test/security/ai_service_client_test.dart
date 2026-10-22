import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/services/ai_service_client.dart';

class _AllowLoopbackHttpOverrides extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AllowLoopbackHttpOverrides();

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

  group('B3 - AI Service Rate Limiting and Error Handling', () {
    late HttpServer server;
    late String serverUrl;
    late File dummyFile;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUrl = 'http://127.0.0.1:${server.port}';
      dummyFile = File('${Directory.systemTemp.path}/test_image.png');
      await dummyFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    });

    tearDown(() async {
      await server.close(force: true);
      if (await dummyFile.exists()) {
        await dummyFile.delete();
      }
    });

    test('extractEncoding throws descriptive exception on HTTP 429 rate limit', () async {
      server.listen((HttpRequest request) {
        request.response.statusCode = HttpStatus.tooManyRequests;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"detail":"Too Many Requests: Rate limit exceeded (120 req/min)"}');
        request.response.close();
      });

      final client = AIServiceClient(serviceKey: 'test-key', baseUrl: serverUrl);
      expect(
        () async => await client.extractEncoding(dummyFile),
        throwsA(predicate((e) => e.toString().contains('Too Many Requests') || e.toString().contains('Rate limit'))),
      );
    });

    test('checkEyesClosed rethrows on HTTP 429 rate limit so caller knows to throttle', () async {
      server.listen((HttpRequest request) {
        request.response.statusCode = HttpStatus.tooManyRequests;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"detail":"Too Many Requests: Rate limit exceeded"}');
        request.response.close();
      });

      final client = AIServiceClient(serviceKey: 'test-key', baseUrl: serverUrl);
      expect(
        () async => await client.checkEyesClosed(dummyFile),
        throwsA(predicate((e) => e.toString().contains('Too Many Requests'))),
      );
    });

    test('extractEncoding surfaces bad request details on HTTP 400 (e.g. invalid magic bytes)', () async {
      server.listen((HttpRequest request) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"detail":"Invalid image format: unsupported or missing magic bytes"}');
        request.response.close();
      });

      final client = AIServiceClient(serviceKey: 'test-key', baseUrl: serverUrl);
      expect(
        () async => await client.extractEncoding(dummyFile),
        throwsA(predicate((e) => e.toString().contains('Invalid image format'))),
      );
    });
  });
}
