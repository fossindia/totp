import 'package:flutter/foundation.dart';

/// Base class for all application errors
class AppError extends Error {
  final String message;
  final String code;
  final String? details;
  final StackTrace? errorStackTrace;

  AppError(this.message, this.code, {this.details, StackTrace? stackTrace})
    : errorStackTrace = stackTrace;

  @override
  StackTrace? get stackTrace => errorStackTrace;

  @override
  String toString() => 'AppError: $code - $message';

  /// Get user-friendly error message (safe for display)
  String get userFriendlyMessage {
    switch (code) {
      case 'ENCRYPTION_ERROR':
        return 'Failed to secure data. Please try again.';
      case 'DECRYPTION_ERROR':
        return 'Failed to access secure data. Please restart the app.';
      case 'INVALID_QR_CODE':
        return 'The QR code format is not supported.';
      case 'INVALID_SECRET':
        return 'The QR code contains invalid security data.';
      case 'AUTHENTICATION_FAILED':
        return 'Authentication failed. Please try again.';
      case 'STORAGE_ERROR':
        return 'Failed to save data. Please check device storage.';
      case 'NETWORK_ERROR':
        return 'Network connection required.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Log error details (only in debug mode)
  void logError() {
    if (kDebugMode) {
      print('AppError [$code]: $message');
      if (details != null) {
        print('Details: $details');
      }
      if (stackTrace != null) {
        print('StackTrace: $stackTrace');
      }
    }
  }
}

/// Encryption/Decryption related errors
class EncryptionError extends AppError {
  EncryptionError(String message, {String? details, StackTrace? stackTrace})
    : super(
        message,
        'ENCRYPTION_ERROR',
        details: details,
        stackTrace: stackTrace,
      );
}

class DecryptionError extends AppError {
  DecryptionError(String message, {String? details, StackTrace? stackTrace})
    : super(
        message,
        'DECRYPTION_ERROR',
        details: details,
        stackTrace: stackTrace,
      );
}

/// Authentication related errors
class AuthenticationError extends AppError {
  AuthenticationError(String message, {String? details, StackTrace? stackTrace})
    : super(
        message,
        'AUTHENTICATION_ERROR',
        details: details,
        stackTrace: stackTrace,
      );
}

/// Storage related errors
class StorageError extends AppError {
  StorageError(String message, {String? details, StackTrace? stackTrace})
    : super(message, 'STORAGE_ERROR', details: details, stackTrace: stackTrace);
}

/// Validation related errors
class ValidationError extends AppError {
  ValidationError(String message, {String? details, StackTrace? stackTrace})
    : super(
        message,
        'VALIDATION_ERROR',
        details: details,
        stackTrace: stackTrace,
      );
}
