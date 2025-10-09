import 'package:totp_generator/totp_generator.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:totp/src/core/services/performance_monitor_service.dart';

// Background computation function for TOTP generation
String _generateTotpInBackground(_TotpGenerationParams params) {
  final totp = TOTPGenerator();
  return totp.generateTOTP(
    secret: params.secret,
    encoding: params.encoding,
    algorithm: params.algorithm,
    interval: params.interval,
  );
}

// Background computation function for batch TOTP generation
List<String> _generateBatchTotpInBackground(_BatchTotpGenerationParams params) {
  final totp = TOTPGenerator();
  return params.secrets.map((secret) {
    return totp.generateTOTP(
      secret: secret,
      encoding: params.encoding,
      algorithm: params.algorithm,
      interval: params.interval,
    );
  }).toList();
}

// Parameters for background TOTP generation
class _TotpGenerationParams {
  final String secret;
  final String encoding;
  final HashAlgorithm algorithm;
  final int interval;

  _TotpGenerationParams({
    required this.secret,
    required this.encoding,
    required this.algorithm,
    required this.interval,
  });
}

// Parameters for batch background TOTP generation
class _BatchTotpGenerationParams {
  final List<String> secrets;
  final String encoding;
  final HashAlgorithm algorithm;
  final int interval;

  _BatchTotpGenerationParams({
    required this.secrets,
    required this.encoding,
    required this.algorithm,
    required this.interval,
  });
}

class TotpService {
  static const int _defaultInterval = 30;

  // Cache for generated TOTP codes
  final Map<String, _TotpCacheEntry> _cache = {};
  Timer? _cleanupTimer;

  TotpService() {
    // Clean up expired cache entries every minute
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _cleanupExpiredEntries();
    });
  }

  Future<String> generateTotpAsync(
    String secret, {
    int interval = _defaultInterval,
  }) async {
    final timer = PerformanceTimer('TOTP Generation Async');

    try {
      final cacheKey = '${secret}_$interval';
      final now = DateTime.now();
      final currentTimeWindow = now.millisecondsSinceEpoch ~/ (interval * 1000);

      // Check if we have a valid cached entry
      final cachedEntry = _cache[cacheKey];
      if (cachedEntry != null && cachedEntry.timeWindow == currentTimeWindow) {
        PerformanceMonitor.recordEvent(
          'TOTP Cache Hit Async',
          PerformanceEventType.cache,
          metadata: {'secret_length': secret.length, 'interval': interval},
        );
        timer.finish(additionalMetadata: {'result': 'cache_hit'});
        return cachedEntry.code;
      }

      // Generate new TOTP code in background isolate
      final params = _TotpGenerationParams(
        secret: secret,
        encoding: 'base32',
        algorithm: HashAlgorithm.sha1,
        interval: interval,
      );

      final newCode = await compute(_generateTotpInBackground, params);

      // Cache the new code
      _cache[cacheKey] = _TotpCacheEntry(
        code: newCode,
        timeWindow: currentTimeWindow,
        expiryTime: now.add(
          Duration(seconds: interval + 5),
        ), // Add 5 second buffer
      );

      PerformanceMonitor.recordEvent(
        'TOTP Generation Async',
        PerformanceEventType.operation,
        metadata: {'secret_length': secret.length, 'interval': interval},
      );

      timer.finish(additionalMetadata: {'result': 'generated'});
      return newCode;
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  String generateTotp(String secret, {int interval = _defaultInterval}) {
    final timer = PerformanceTimer('TOTP Generation Sync');

    try {
      final cacheKey = '${secret}_$interval';
      final now = DateTime.now();
      final currentTimeWindow = now.millisecondsSinceEpoch ~/ (interval * 1000);

      // Check if we have a valid cached entry
      final cachedEntry = _cache[cacheKey];
      if (cachedEntry != null && cachedEntry.timeWindow == currentTimeWindow) {
        PerformanceMonitor.recordEvent(
          'TOTP Cache Hit',
          PerformanceEventType.cache,
          metadata: {'secret_length': secret.length, 'interval': interval},
        );
        timer.finish(additionalMetadata: {'result': 'cache_hit'});
        return cachedEntry.code;
      }

      // Generate new TOTP code (synchronous for backward compatibility)
      final totp = TOTPGenerator();
      final newCode = totp.generateTOTP(
        secret: secret,
        encoding: 'base32',
        algorithm: HashAlgorithm.sha1,
        interval: interval,
      );

      // Cache the new code
      _cache[cacheKey] = _TotpCacheEntry(
        code: newCode,
        timeWindow: currentTimeWindow,
        expiryTime: now.add(
          Duration(seconds: interval + 5),
        ), // Add 5 second buffer
      );

      PerformanceMonitor.recordEvent(
        'TOTP Generation',
        PerformanceEventType.operation,
        metadata: {'secret_length': secret.length, 'interval': interval},
      );

      timer.finish(additionalMetadata: {'result': 'generated'});
      return newCode;
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  int getRemainingSeconds({int interval = _defaultInterval}) {
    final now = DateTime.now();
    final secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    return interval - (secondsSinceEpoch % interval);
  }

  /// Get TOTP code with remaining time information
  TotpCodeInfo getTotpWithTimeInfo(
    String secret, {
    int interval = _defaultInterval,
  }) {
    final code = generateTotp(secret, interval: interval);
    final remainingSeconds = getRemainingSeconds(interval: interval);

    return TotpCodeInfo(
      code: code,
      remainingSeconds: remainingSeconds,
      interval: interval,
    );
  }

  /// Preload TOTP codes for multiple secrets (useful for list views)
  void preloadTotpCodes(
    List<String> secrets, {
    int interval = _defaultInterval,
  }) {
    final timer = PerformanceTimer('TOTP Batch Preload Sync', {
      'batch_size': secrets.length,
    });

    try {
      for (final secret in secrets) {
        generateTotp(secret, interval: interval);
      }

      PerformanceMonitor.recordEvent(
        'TOTP Batch Preload',
        PerformanceEventType.operation,
        metadata: {'batch_size': secrets.length, 'interval': interval},
      );

      timer.finish(additionalMetadata: {'result': 'success'});
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Preload TOTP codes asynchronously for better performance
  Future<void> preloadTotpCodesAsync(
    List<String> secrets, {
    int interval = _defaultInterval,
  }) async {
    final timer = PerformanceTimer('TOTP Batch Preload Async', {
      'batch_size': secrets.length,
    });

    try {
      if (secrets.isEmpty) {
        timer.finish(additionalMetadata: {'result': 'empty_batch'});
        return;
      }

      // Use batch processing for better performance
      final params = _BatchTotpGenerationParams(
        secrets: secrets,
        encoding: 'base32',
        algorithm: HashAlgorithm.sha1,
        interval: interval,
      );

      final codes = await compute(_generateBatchTotpInBackground, params);

      final now = DateTime.now();
      final currentTimeWindow = now.millisecondsSinceEpoch ~/ (interval * 1000);

      // Cache all generated codes
      for (int i = 0; i < secrets.length; i++) {
        final secret = secrets[i];
        final code = codes[i];
        final cacheKey = '${secret}_$interval';

        _cache[cacheKey] = _TotpCacheEntry(
          code: code,
          timeWindow: currentTimeWindow,
          expiryTime: now.add(
            Duration(seconds: interval + 5),
          ), // Add 5 second buffer
        );
      }

      PerformanceMonitor.recordEvent(
        'TOTP Batch Preload Async',
        PerformanceEventType.operation,
        metadata: {'batch_size': secrets.length, 'interval': interval},
      );

      timer.finish(additionalMetadata: {'result': 'success'});
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Clear all cached entries
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final validEntries = _cache.values
        .where((entry) => entry.expiryTime.isAfter(now))
        .length;

    final stats = {
      'total_entries': _cache.length,
      'valid_entries': validEntries,
      'expired_entries': _cache.length - validEntries,
    };

    // Record cache statistics for monitoring
    PerformanceMonitor.recordCacheMetrics(
      'TOTP Cache',
      hits: validEntries, // Approximate hits as valid entries
      misses: _cache.length - validEntries,
      totalRequests: _cache.length,
    );

    return stats;
  }

  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => entry.expiryTime.isBefore(now));
  }

  /// Dispose of resources
  void dispose() {
    _cleanupTimer?.cancel();
    clearCache();
  }
}

/// Data class for TOTP code with timing information
class TotpCodeInfo {
  final String code;
  final int remainingSeconds;
  final int interval;

  const TotpCodeInfo({
    required this.code,
    required this.remainingSeconds,
    required this.interval,
  });

  /// Get progress as a fraction (0.0 to 1.0)
  double get progress => (interval - remainingSeconds) / interval;

  /// Check if the code is about to expire (less than 5 seconds remaining)
  bool get isExpiringSoon => remainingSeconds <= 5;
}

/// Internal cache entry model
class _TotpCacheEntry {
  final String code;
  final int timeWindow;
  final DateTime expiryTime;

  _TotpCacheEntry({
    required this.code,
    required this.timeWindow,
    required this.expiryTime,
  });
}
