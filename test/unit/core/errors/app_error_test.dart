import 'package:flutter_test/flutter_test.dart';
import 'package:totp/src/core/errors/app_error.dart';

void main() {
  group('AppError', () {
    test('should create AppError with required parameters', () {
      const message = 'Test error';
      const code = 'TEST_ERROR';

      final error = AppError(message, code);

      expect(error.message, equals(message));
      expect(error.code, equals(code));
      expect(error.details, isNull);
      expect(error.errorStackTrace, isNull);
    });

    test('should create AppError with optional parameters', () {
      const message = 'Test error';
      const code = 'TEST_ERROR';
      const details = 'Additional details';
      final stackTrace = StackTrace.current;

      final error = AppError(
        message,
        code,
        details: details,
        stackTrace: stackTrace,
      );

      expect(error.message, equals(message));
      expect(error.code, equals(code));
      expect(error.details, equals(details));
      expect(error.errorStackTrace, equals(stackTrace));
    });

    test('should return correct toString', () {
      const message = 'Test error';
      const code = 'TEST_ERROR';

      final error = AppError(message, code);

      expect(error.toString(), equals('AppError: TEST_ERROR - Test error'));
    });

    test('should return user-friendly message for known error codes', () {
      final encryptionError = EncryptionError('Encryption failed');
      final decryptionError = DecryptionError('Decryption failed');
      final authError = AuthenticationError('Auth failed');
      final storageError = StorageError('Storage failed');
      final validationError = ValidationError('Validation failed');

      expect(
        encryptionError.userFriendlyMessage,
        equals('Failed to secure data. Please try again.'),
      );
      expect(
        decryptionError.userFriendlyMessage,
        equals('Failed to access secure data. Please restart the app.'),
      );
      expect(
        authError.userFriendlyMessage,
        equals('Authentication failed. Please try again.'),
      );
      expect(
        storageError.userFriendlyMessage,
        equals('Failed to save data. Please check device storage.'),
      );
      expect(
        validationError.userFriendlyMessage,
        equals('An unexpected error occurred. Please try again.'),
      );
    });

    test(
      'should return default user-friendly message for unknown error codes',
      () {
        final unknownError = AppError('Unknown error', 'UNKNOWN_ERROR');

        expect(
          unknownError.userFriendlyMessage,
          equals('An unexpected error occurred. Please try again.'),
        );
      },
    );

    test('should log error in debug mode', () {
      const message = 'Test error';
      const code = 'TEST_ERROR';
      const details = 'Test details';
      final stackTrace = StackTrace.current;

      final error = AppError(
        message,
        code,
        details: details,
        stackTrace: stackTrace,
      );

      // In test environment, logging should not throw
      expect(() => error.logError(), returnsNormally);
    });
  });

  group('EncryptionError', () {
    test('should create EncryptionError correctly', () {
      const message = 'Encryption failed';
      const details = 'Key not found';
      final stackTrace = StackTrace.current;

      final error = EncryptionError(
        message,
        details: details,
        stackTrace: stackTrace,
      );

      expect(error.message, equals(message));
      expect(error.code, equals('ENCRYPTION_ERROR'));
      expect(error.details, equals(details));
      expect(error.errorStackTrace, equals(stackTrace));
    });
  });

  group('DecryptionError', () {
    test('should create DecryptionError correctly', () {
      const message = 'Decryption failed';

      final error = DecryptionError(message);

      expect(error.message, equals(message));
      expect(error.code, equals('DECRYPTION_ERROR'));
    });
  });

  group('AuthenticationError', () {
    test('should create AuthenticationError correctly', () {
      const message = 'Authentication failed';

      final error = AuthenticationError(message);

      expect(error.message, equals(message));
      expect(error.code, equals('AUTHENTICATION_ERROR'));
    });
  });

  group('StorageError', () {
    test('should create StorageError correctly', () {
      const message = 'Storage operation failed';

      final error = StorageError(message);

      expect(error.message, equals(message));
      expect(error.code, equals('STORAGE_ERROR'));
    });
  });

  group('ValidationError', () {
    test('should create ValidationError correctly', () {
      const message = 'Validation failed';

      final error = ValidationError(message);

      expect(error.message, equals(message));
      expect(error.code, equals('VALIDATION_ERROR'));
    });
  });
}
