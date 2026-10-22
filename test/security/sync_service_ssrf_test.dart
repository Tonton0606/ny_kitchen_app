import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/services/sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('B4 - SSRF Image URL Protection (Gap 18)', () {
    const trustedHost = 'https://myproject.supabase.co';

    test('isSafeImageUrl permits valid Supabase URLs', () {
      expect(
        SyncService.isSafeImageUrl(
          'https://myproject.supabase.co/storage/v1/object/public/food_images/adobo.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isTrue,
      );

      expect(
        SyncService.isSafeImageUrl(
          'https://otherproject.supabase.co/storage/v1/object/public/food_images/sinigang.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isTrue,
      );
    });

    test('isSafeImageUrl rejects non-https schemes (http, file, ftp)', () {
      expect(
        SyncService.isSafeImageUrl(
          'http://myproject.supabase.co/image.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );

      expect(
        SyncService.isSafeImageUrl(
          'file:///etc/passwd',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );

      expect(
        SyncService.isSafeImageUrl(
          'ftp://myproject.supabase.co/image.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );
    });

    test('isSafeImageUrl rejects lookalike and unauthorized hosts', () {
      expect(
        SyncService.isSafeImageUrl(
          'https://supabase.co.evil.com/image.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );

      expect(
        SyncService.isSafeImageUrl(
          'https://evil.com/supabase.co/image.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );

      expect(
        SyncService.isSafeImageUrl(
          'https://google.com/test.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );

      expect(
        SyncService.isSafeImageUrl(
          'https://not-supabase.co/image.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );
    });

    test('isSafeImageUrl rejects credentials and non-standard ports', () {
      expect(
        SyncService.isSafeImageUrl(
          'https://admin:password@myproject.supabase.co/image.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );

      expect(
        SyncService.isSafeImageUrl(
          'https://myproject.supabase.co:8443/image.png',
          trustedSupabaseUrl: trustedHost,
        ),
        isFalse,
      );
    });

    test('isPrivateOrLoopbackIp flags private, loopback, and metadata IPs', () {
      expect(SyncService.isPrivateOrLoopbackIp(InternetAddress('127.0.0.1')), isTrue);
      expect(SyncService.isPrivateOrLoopbackIp(InternetAddress('10.0.0.1')), isTrue);
      expect(SyncService.isPrivateOrLoopbackIp(InternetAddress('172.16.0.1')), isTrue);
      expect(SyncService.isPrivateOrLoopbackIp(InternetAddress('192.168.1.1')), isTrue);
      expect(SyncService.isPrivateOrLoopbackIp(InternetAddress('169.254.169.254')), isTrue);
      expect(SyncService.isPrivateOrLoopbackIp(InternetAddress('::1')), isTrue);
      expect(SyncService.isPrivateOrLoopbackIp(InternetAddress('8.8.8.8')), isFalse);
    });
  });
}
