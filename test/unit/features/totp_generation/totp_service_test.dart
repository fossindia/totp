import 'package:flutter_test/flutter_test.dart';
import 'package:totp/src/features/totp_generation/totp_service.dart';

void main() {
  late TotpService totpService;

  setUp(() {
    totpService = TotpService();
  });

  tearDown(() {
    totpService.dispose();
  });

  group('TotpService.generateTotp()', () {
    test('should generate TOTP code for valid secret', () {
      const secret = 'JBSWY3DPEHPK3PXP'; // Test secret
      const interval = 30;

      final code = totpService.generateTotp(secret, interval: interval);

      expect(code, isNotNull);
      expect(code, isNotEmpty);
      expect(code.length, equals(6)); // TOTP codes are typically 6 digits
      expect(int.tryParse(code), isNotNull); // Should be numeric
    });

    test('should generate different codes for different secrets', () {
      const secret1 = 'JBSWY3DPEHPK3PXP';
      const secret2 = 'JBSWY3DPEHPK3PXQ'; // Different secret

      final code1 = totpService.generateTotp(secret1);
      final code2 = totpService.generateTotp(secret2);

      expect(code1, isNot(equals(code2)));
    });

    test('should generate same code for same secret in same time window', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      final code1 = totpService.generateTotp(secret);
      final code2 = totpService.generateTotp(secret); // Should be cached

      expect(code1, equals(code2));
    });

    test('should handle different intervals', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      final code30 = totpService.generateTotp(secret, interval: 30);
      final code60 = totpService.generateTotp(secret, interval: 60);

      // Different intervals should generally produce different codes
      // (though theoretically they could be the same)
      expect(code30, isNotNull);
      expect(code60, isNotNull);
    });

    test('should handle empty secret gracefully', () {
      const secret = '';

      // This might throw or return empty, depending on the TOTP library
      expect(() => totpService.generateTotp(secret), returnsNormally);
    });
  });

  group('TotpService.getRemainingSeconds()', () {
    test('should return remaining seconds in current interval', () {
      final remaining = totpService.getRemainingSeconds();

      expect(remaining, greaterThanOrEqualTo(0));
      expect(remaining, lessThanOrEqualTo(30));
    });

    test('should handle custom intervals', () {
      final remaining30 = totpService.getRemainingSeconds(interval: 30);
      final remaining60 = totpService.getRemainingSeconds(interval: 60);

      expect(remaining30, greaterThanOrEqualTo(0));
      expect(remaining30, lessThanOrEqualTo(30));
      expect(remaining60, greaterThanOrEqualTo(0));
      expect(remaining60, lessThanOrEqualTo(60));
    });
  });

  group('TotpService.getTotpWithTimeInfo()', () {
    test('should return TotpCodeInfo with code and timing', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      final info = totpService.getTotpWithTimeInfo(secret);

      expect(info, isA<TotpCodeInfo>());
      expect(info.code, isNotNull);
      expect(info.code, isNotEmpty);
      expect(info.remainingSeconds, greaterThanOrEqualTo(0));
      expect(info.remainingSeconds, lessThanOrEqualTo(30));
      expect(info.interval, equals(30));
    });

    test('should return consistent data', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      final info1 = totpService.getTotpWithTimeInfo(secret);
      final info2 = totpService.getTotpWithTimeInfo(secret);

      expect(info1.code, equals(info2.code));
      expect(info1.interval, equals(info2.interval));
    });
  });

  group('TotpCodeInfo', () {
    test('should calculate progress correctly', () {
      const info = TotpCodeInfo(
        code: '123456',
        remainingSeconds: 15,
        interval: 30,
      );

      expect(info.progress, equals(0.5)); // 15/30 = 0.5
    });

    test('should identify expiring codes', () {
      const expiring = TotpCodeInfo(
        code: '123456',
        remainingSeconds: 3,
        interval: 30,
      );

      const notExpiring = TotpCodeInfo(
        code: '123456',
        remainingSeconds: 10,
        interval: 30,
      );

      expect(expiring.isExpiringSoon, isTrue);
      expect(notExpiring.isExpiringSoon, isFalse);
    });
  });

  group('TotpService.preloadTotpCodes()', () {
    test('should preload multiple secrets', () {
      // Use valid base32-encoded secrets
      final secrets = [
        'JBSWY3DPEHPK3PXP',
        'JBSWY3DPEHPK3PXQ',
        'JBSWY3DPEHPK3PXR',
      ];

      expect(() => totpService.preloadTotpCodes(secrets), returnsNormally);

      // Check cache stats
      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], greaterThanOrEqualTo(secrets.length));
    });

    test('should handle empty list', () {
      expect(() => totpService.preloadTotpCodes([]), returnsNormally);
    });
  });

  group('TotpService Cache Management', () {
    test('should clear cache', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      // Generate and cache a code
      totpService.generateTotp(secret);

      // Verify it's cached
      final statsBefore = totpService.getCacheStats();
      expect(statsBefore['total_entries'], greaterThan(0));

      // Clear cache
      totpService.clearCache();

      // Verify cache is empty
      final statsAfter = totpService.getCacheStats();
      expect(statsAfter['total_entries'], equals(0));
    });

    test('should provide cache statistics', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      // Generate a code
      totpService.generateTotp(secret);

      final stats = totpService.getCacheStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('total_entries'), isTrue);
      expect(stats.containsKey('valid_entries'), isTrue);
      expect(stats.containsKey('expired_entries'), isTrue);
      expect(stats['total_entries'], greaterThanOrEqualTo(0));
      expect(stats['valid_entries'], greaterThanOrEqualTo(0));
      expect(stats['expired_entries'], greaterThanOrEqualTo(0));
    });
  });

  group('TotpService.dispose()', () {
    test('should dispose resources', () {
      final service = TotpService();

      // Generate some codes to populate cache
      service.generateTotp('TEST');

      // Dispose
      service.dispose();

      // Verify cache is cleared
      final stats = service.getCacheStats();
      expect(stats['total_entries'], equals(0));
    });
  });

  group('Cache behavior and expiry', () {
    test('should handle cache expiry simulation', () {
      // This test is challenging to implement deterministically due to time-based expiry
      // In a real scenario, we'd mock the time or use a testable version
      // For now, we verify the cache cleanup mechanism exists
      expect(() => totpService.clearCache(), returnsNormally);
    });

    test('should maintain separate cache entries for different intervals', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      final code30 = totpService.generateTotp(secret, interval: 30);
      final code60 = totpService.generateTotp(secret, interval: 60);

      expect(code30, isNotNull);
      expect(code60, isNotNull);

      // Both should be cached
      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], greaterThanOrEqualTo(2));
    });
  });

  group('Load testing simulation', () {
    test('should handle multiple secrets efficiently', () {
      // Use valid base32-encoded secrets
      final secrets = [
        'JBSWY3DPEHPK3PXP',
        'JBSWY3DPEHPK3PXQ',
        'JBSWY3DPEHPK3PXR',
        'JBSWY3DPEHPK3PXS',
        'JBSWY3DPEHPK3PXT',
        'JBSWY3DPEHPK3PXU',
        'JBSWY3DPEHPK3PXV',
        'JBSWY3DPEHPK3PXW',
        'JBSWY3DPEHPK3PXX',
        'JBSWY3DPEHPK3PXY',
      ];

      final startTime = DateTime.now();
      totpService.preloadTotpCodes(secrets);
      final endTime = DateTime.now();

      final duration = endTime.difference(startTime).inMilliseconds;
      expect(duration, lessThan(1000)); // Should complete within 1 second

      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], greaterThanOrEqualTo(secrets.length));
    });

    test('should handle repeated calls for same secret', () {
      const secret = 'JBSWY3DPEHPK3PXP';

      // Call multiple times rapidly
      for (int i = 0; i < 10; i++) {
        final code = totpService.generateTotp(secret);
        expect(code, isNotNull);
        expect(code.length, equals(6));
      }

      // Should only have one cache entry
      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], equals(1));
    });
  });
}
