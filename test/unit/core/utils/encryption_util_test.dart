import 'package:flutter_test/flutter_test.dart';
import 'package:totp/src/core/utils/encryption_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Note: Testing static methods with secure storage is challenging
  // These tests focus on the public interface behavior

  group('EncryptionUtil.init()', () {
    test('should complete without throwing exceptions', () async {
      // Test that init can be called multiple times without issues
      await EncryptionUtil.init();
      await EncryptionUtil.init();

      // If we get here without exceptions, the test passes
      expect(true, isTrue);
    });
  });

  group('EncryptionUtil.encrypt()', () {
    test('should throw StateError when not initialized', () {
      expect(() => EncryptionUtil.encrypt('test'), throwsStateError);
    });

    test('should encrypt and decrypt successfully when initialized', () async {
      // Initialize first
      await EncryptionUtil.init();

      // Test encrypt/decrypt round trip
      const testData = 'Hello, World!';
      final encrypted = EncryptionUtil.encrypt(testData);
      final decrypted = EncryptionUtil.decrypt(encrypted);

      expect(decrypted, equals(testData));
      expect(encrypted, isNot(equals(testData)));
      expect(encrypted, isNotEmpty);
    });

    test('should handle empty strings', () async {
      await EncryptionUtil.init();

      const testData = '';
      final encrypted = EncryptionUtil.encrypt(testData);
      final decrypted = EncryptionUtil.decrypt(encrypted);

      expect(decrypted, equals(testData));
    });

    test('should handle special characters', () async {
      await EncryptionUtil.init();

      const testData = 'Special chars: !@#\$%^&*()_+{}|:<>?[]\\;\'",./';
      final encrypted = EncryptionUtil.encrypt(testData);
      final decrypted = EncryptionUtil.decrypt(encrypted);

      expect(decrypted, equals(testData));
    });

    test('should handle unicode characters', () async {
      await EncryptionUtil.init();

      const testData = 'Unicode: 你好世界 🌍 éñ';
      final encrypted = EncryptionUtil.encrypt(testData);
      final decrypted = EncryptionUtil.decrypt(encrypted);

      expect(decrypted, equals(testData));
    });

    test(
      'should generate different encrypted outputs for same input',
      () async {
        await EncryptionUtil.init();

        const testData = 'Same input';
        final encrypted1 = EncryptionUtil.encrypt(testData);
        final encrypted2 = EncryptionUtil.encrypt(testData);

        expect(encrypted1, isNot(equals(encrypted2)));
        // But both should decrypt to the same value
        expect(EncryptionUtil.decrypt(encrypted1), equals(testData));
        expect(EncryptionUtil.decrypt(encrypted2), equals(testData));
      },
    );
  });

  group('EncryptionUtil.decrypt()', () {
    test('should throw StateError when not initialized', () {
      expect(() => EncryptionUtil.decrypt('invalid'), throwsStateError);
    });

    test('should throw StateError for invalid base64 data', () async {
      await EncryptionUtil.init();

      expect(
        () => EncryptionUtil.decrypt('invalid base64!@#'),
        throwsStateError,
      );
    });

    test('should throw StateError for corrupted encrypted data', () async {
      await EncryptionUtil.init();

      // Create valid encrypted data then corrupt it
      final validEncrypted = EncryptionUtil.encrypt('test');
      final corrupted = validEncrypted.replaceFirst('A', 'Z');

      expect(() => EncryptionUtil.decrypt(corrupted), throwsStateError);
    });

    test('should throw StateError for too short data', () async {
      await EncryptionUtil.init();

      expect(() => EncryptionUtil.decrypt('short'), throwsStateError);
    });
  });

  group('EncryptionUtil.rotateKeys()', () {
    test('should complete without errors', () async {
      await EncryptionUtil.init();

      // Store original encrypted data
      const testData = 'test data';
      final originalEncrypted = EncryptionUtil.encrypt(testData);

      // Rotate keys using new method
      await EncryptionUtil.performKeyRotation();

      // Verify new encryption works
      final newEncrypted = EncryptionUtil.encrypt(testData);
      final newDecrypted = EncryptionUtil.decrypt(newEncrypted);

      expect(newDecrypted, equals(testData));
      // New encrypted data should be different from old
      expect(newEncrypted, isNot(equals(originalEncrypted)));
    });
  });

  group('EncryptionUtil.validateKeySecurity()', () {
    test('should return true for valid keys', () async {
      await EncryptionUtil.init();

      final isValid = await EncryptionUtil.validateKeySecurity();

      expect(isValid, isTrue);
    });

    test('should return false when encryption fails', () async {
      // Test without initialization
      final isValid = await EncryptionUtil.validateKeySecurity();

      expect(isValid, isFalse);
    });
  });

  group('Edge cases and error handling', () {
    test('should handle very long input strings', () async {
      await EncryptionUtil.init();

      final longString = 'A' * 10000;
      final encrypted = EncryptionUtil.encrypt(longString);
      final decrypted = EncryptionUtil.decrypt(encrypted);

      expect(decrypted, equals(longString));
    });

    test('should handle binary data as strings', () async {
      await EncryptionUtil.init();

      // Create a string with null bytes and other binary-like content
      final binaryString = String.fromCharCodes(List.generate(256, (i) => i));
      final encrypted = EncryptionUtil.encrypt(binaryString);
      final decrypted = EncryptionUtil.decrypt(encrypted);

      expect(decrypted, equals(binaryString));
    });
  });
}
