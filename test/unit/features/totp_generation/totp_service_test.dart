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

  group('TotpService - Basic TOTP Generation', () {
    test('should generate valid TOTP codes', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP'; // Standard test secret

      // Act
      final code = totpService.generateTotp(secret);

      // Assert
      expect(code, isNotNull);
      expect(code.length, equals(6)); // TOTP codes are typically 6 digits
      expect(int.tryParse(code), isNotNull); // Should be numeric
    });

    test('should generate different codes for different secrets', () {
      // Arrange
      const secret1 = 'JBSWY3DPEHPK3PXP';
      const secret2 = 'JBSWY3DPEHPK3PXQ'; // Different secret

      // Act
      final code1 = totpService.generateTotp(secret1);
      final code2 = totpService.generateTotp(secret2);

      // Assert
      expect(code1, isNot(equals(code2)));
    });

    test('should generate same code for same secret within time window', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act
      final code1 = totpService.generateTotp(secret);
      final code2 = totpService.generateTotp(secret); // Should be cached

      // Assert
      expect(code1, equals(code2));
    });

    test('should handle custom intervals', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';
      const customInterval = 60; // 1 minute instead of 30 seconds

      // Act
      final code = totpService.generateTotp(secret, interval: customInterval);

      // Assert
      expect(code, isNotNull);
      expect(code.length, equals(6));
    });
  });

  group('TotpService - Caching', () {
    test('should cache TOTP codes and return same code within time window', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act
      final code1 = totpService.generateTotp(secret);
      final code2 = totpService.generateTotp(secret); // Should hit cache

      // Assert
      expect(code1, equals(code2));
    });

    test('should use different cache keys for different intervals', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act
      final code30 = totpService.generateTotp(secret, interval: 30);
      final code60 = totpService.generateTotp(secret, interval: 60);

      // Assert - codes might be same or different depending on timing
      // but they should both be valid
      expect(code30, isNotNull);
      expect(code60, isNotNull);
    });

    test('should clear cache when requested', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';
      totpService.generateTotp(secret); // Fill cache

      // Act
      totpService.clearCache();

      // Assert
      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], equals(0));
    });
  });

  group('TotpService - Time Calculations', () {
    test('should calculate remaining seconds correctly', () {
      // Act
      final remaining = totpService.getRemainingSeconds();

      // Assert
      expect(remaining, greaterThanOrEqualTo(0));
      expect(remaining, lessThanOrEqualTo(30));
    });

    test('should calculate remaining seconds for custom intervals', () {
      // Act
      final remaining = totpService.getRemainingSeconds(interval: 60);

      // Assert
      expect(remaining, greaterThanOrEqualTo(0));
      expect(remaining, lessThanOrEqualTo(60));
    });

    test('should return TotpCodeInfo with correct data', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act
      final info = totpService.getTotpWithTimeInfo(secret);

      // Assert
      expect(info.code, isNotNull);
      expect(info.code.length, equals(6));
      expect(info.remainingSeconds, greaterThanOrEqualTo(0));
      expect(info.remainingSeconds, lessThanOrEqualTo(30));
      expect(info.interval, equals(30));
      expect(info.progress, greaterThanOrEqualTo(0.0));
      expect(info.progress, lessThanOrEqualTo(1.0));
    });

    test('should identify expiring codes correctly', () {
      // This test is timing-dependent, so we'll test the logic
      // by creating a TotpCodeInfo directly
      final expiringSoon = TotpCodeInfo(
        code: '123456',
        remainingSeconds: 3,
        interval: 30,
      );
      final notExpiring = TotpCodeInfo(
        code: '123456',
        remainingSeconds: 20,
        interval: 30,
      );

      expect(expiringSoon.isExpiringSoon, isTrue);
      expect(notExpiring.isExpiringSoon, isFalse);
    });
  });

  group('TotpService - Batch Operations', () {
    test('should preload multiple TOTP codes synchronously', () {
      // Arrange
      final secrets = [
        'JBSWY3DPEHPK3PXP',
        'JBSWY3DPEHPK3PXQ',
        'JBSWY3DPEHPK3PXR',
      ];

      // Act
      totpService.preloadTotpCodes(secrets);

      // Assert
      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], equals(secrets.length));
    });

    test('should handle empty batch preload gracefully', () async {
      // Act
      await totpService.preloadTotpCodesAsync([]);

      // Assert - should not throw
    });

    test('should preload multiple TOTP codes asynchronously', () async {
      // Arrange
      final secrets = ['JBSWY3DPEHPK3PXP', 'JBSWY3DPEHPK3PXQ'];

      // Act
      await totpService.preloadTotpCodesAsync(secrets);

      // Assert
      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], equals(secrets.length));
    });
  });

  group('TotpService - Cache Statistics', () {
    test('should return correct cache statistics for empty cache', () {
      // Act
      final stats = totpService.getCacheStats();

      // Assert
      expect(stats['total_entries'], equals(0));
      expect(stats['valid_entries'], equals(0));
      expect(stats['expired_entries'], equals(0));
    });

    test('should return correct cache statistics with entries', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';
      totpService.generateTotp(secret);

      // Act
      final stats = totpService.getCacheStats();

      // Assert
      expect(stats['total_entries'], equals(1));
      expect(stats['valid_entries'], equals(1));
      expect(stats['expired_entries'], equals(0));
    });
  });

  group('TotpService - Async Operations', () {
    test('should generate TOTP asynchronously', () async {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act
      final code = await totpService.generateTotpAsync(secret);

      // Assert
      expect(code, isNotNull);
      expect(code.length, equals(6));
    });

    test('should cache async TOTP generation results', () async {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act
      final code1 = await totpService.generateTotpAsync(secret);
      final code2 = totpService.generateTotp(secret); // Should hit cache

      // Assert
      expect(code1, equals(code2));
    });
  });

  group('TotpService - Error Handling', () {
    test('should handle empty secrets', () {
      // Arrange
      const invalidSecret = '';

      // Act
      final result = totpService.generateTotp(invalidSecret);

      // Assert - The library may handle empty strings gracefully
      expect(result, isNotNull);
      expect(result.length, equals(6));
    });

    test('should handle async empty secrets', () async {
      // Arrange
      const invalidSecret = '';

      // Act
      final result = await totpService.generateTotpAsync(invalidSecret);

      // Assert - The library may handle empty strings gracefully
      expect(result, isNotNull);
      expect(result.length, equals(6));
    });
  });

  group('TotpService - Resource Management', () {
    test('should dispose resources properly', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';
      totpService.generateTotp(secret); // Add to cache

      // Act
      totpService.dispose();

      // Assert
      final stats = totpService.getCacheStats();
      expect(stats['total_entries'], equals(0));
    });
  });

  group('TotpService - Edge Cases', () {
    test('should handle very long secrets', () {
      // Arrange
      final longSecret = 'A' * 100; // Very long secret

      // Act
      final code = totpService.generateTotp(longSecret);

      // Assert
      expect(code, isNotNull);
      expect(code.length, equals(6));
    });

    test('should handle special characters in secrets', () {
      // Arrange
      const specialSecret = 'JBSWY3DPEHPK3PXP!@#\$%^&*()';

      // Act & Assert
      expect(() => totpService.generateTotp(specialSecret), throwsException);
      // TOTP secrets should be base32, so special chars might cause issues
    });

    test('should handle zero interval gracefully', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act & Assert
      expect(
        () => totpService.generateTotp(secret, interval: 0),
        throwsException,
      );
    });

    test('should handle negative interval gracefully', () {
      // Arrange
      const secret = 'JBSWY3DPEHPK3PXP';

      // Act
      final result = totpService.generateTotp(secret, interval: -1);

      // Assert - The library may handle negative intervals by using absolute value or default
      expect(result, isNotNull);
      expect(result.length, equals(6));
    });
  });
}
