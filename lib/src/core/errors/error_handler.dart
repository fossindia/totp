import 'package:flutter/foundation.dart';
import 'package:totp/src/core/errors/app_error.dart';

/// Centralized error handling utility
class ErrorHandler {
  /// Handle and log errors securely
  static void handleError(Object error, StackTrace stackTrace) {
    // Log error details only in debug mode
    if (kDebugMode) {
      print('Error occurred: $error');
      print('StackTrace: $stackTrace');
    }

    // Convert to AppError if needed
    final appError = _convertToAppError(error, stackTrace);

    // Log the error using the AppError's logging method
    appError.logError();
  }

  /// Convert various error types to AppError
  static AppError _convertToAppError(Object error, StackTrace stackTrace) {
    if (error is AppError) {
      return error;
    }

    if (error is FormatException) {
      return ValidationError(
        'Invalid data format',
        details: error.message,
        stackTrace: stackTrace,
      );
    }

    if (error is ArgumentError) {
      return ValidationError(
        'Invalid argument provided',
        details: error.message,
        stackTrace: stackTrace,
      );
    }

    if (error is StateError) {
      return StorageError(
        'Application state error',
        details: error.message,
        stackTrace: stackTrace,
      );
    }

    // Default to generic error
    return AppError(
      'An unexpected error occurred',
      'UNEXPECTED_ERROR',
      details: kDebugMode ? error.toString() : null,
      stackTrace: kDebugMode ? stackTrace : null,
    );
  }

  /// Handle errors from async operations
  static Future<T> handleAsyncError<T>(
    Future<T> Function() operation, {
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      handleError(error, stackTrace);

      if (defaultValue != null) {
        return defaultValue;
      }

      // Re-throw as AppError for the caller to handle
      throw _convertToAppError(error, stackTrace);
    }
  }

  /// Wrap synchronous operations with error handling
  static T handleSyncError<T>(T Function() operation, {T? defaultValue}) {
    try {
      return operation();
    } catch (error, stackTrace) {
      handleError(error, stackTrace);

      if (defaultValue != null) {
        return defaultValue;
      }

      // Re-throw as AppError for the caller to handle
      throw _convertToAppError(error, stackTrace);
    }
  }

  /// Check if an error should be reported to crash analytics
  static bool shouldReportError(AppError error) {
    // Only report non-validation errors in production
    return !kDebugMode &&
           !error.code.contains('VALIDATION') &&
           !error.code.contains('AUTHENTICATION');
  }

  /// Convert various error types to AppError (public method for testing)
  static AppError convertToAppError(Object error, StackTrace stackTrace) {
    return _convertToAppError(error, stackTrace);
  }
}

/// Extension to easily handle errors in async operations
extension ErrorHandlingExtension<T> on Future<T> {
  Future<T> onErrorHandle({T? defaultValue}) {
    return ErrorHandler.handleAsyncError(
      () => this,
      defaultValue: defaultValue,
    );
  }
}

/// Extension to easily handle errors in sync operations
extension SyncErrorHandlingExtension<T> on T {
  T onErrorHandle(T defaultValue) {
    return ErrorHandler.handleSyncError(() => this, defaultValue: defaultValue);
  }
}

/// Error handling for TOTP operations
class TotpErrorHandler {
  /// Handle TOTP generation errors
  static String handleTotpGenerationError(Object error, StackTrace stackTrace) {
    ErrorHandler.handleError(error, stackTrace);

    if (error is AppError) {
      return error.userFriendlyMessage;
    }

    return 'Failed to generate TOTP code. Please try again.';
  }

  /// Handle QR code processing errors
  static String handleQrCodeError(Object error, StackTrace stackTrace) {
    ErrorHandler.handleError(error, stackTrace);

    if (error is AppError) {
      return error.userFriendlyMessage;
    }

    return 'Failed to process QR code. Please check the code and try again.';
  }

  /// Handle storage operation errors
  static String handleStorageError(Object error, StackTrace stackTrace) {
    ErrorHandler.handleError(error, stackTrace);

    if (error is AppError) {
      return error.userFriendlyMessage;
    }

    return 'Failed to save data. Please check device storage and try again.';
  }
}
