import 'package:totp_generator/totp_generator.dart';
import 'dart:async';

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

  String generateTotp(String secret, {int interval = _defaultInterval}) {
    final cacheKey = '${secret}_$interval';
    final now = DateTime.now();
    final currentTimeWindow = now.millisecondsSinceEpoch ~/ (interval * 1000);

    // Check if we have a valid cached entry
    final cachedEntry = _cache[cacheKey];
    if (cachedEntry != null && cachedEntry.timeWindow == currentTimeWindow) {
      return cachedEntry.code;
    }

    // Generate new TOTP code
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
      expiryTime: now.add(Duration(seconds: interval + 5)), // Add 5 second buffer
    );

    return newCode;
  }

  int getRemainingSeconds({int interval = _defaultInterval}) {
    final now = DateTime.now();
    final secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;
    return interval - (secondsSinceEpoch % interval);
  }

  /// Get TOTP code with remaining time information
  TotpCodeInfo getTotpWithTimeInfo(String secret, {int interval = _defaultInterval}) {
    final code = generateTotp(secret, interval: interval);
    final remainingSeconds = getRemainingSeconds(interval: interval);

    return TotpCodeInfo(
      code: code,
      remainingSeconds: remainingSeconds,
      interval: interval,
    );
  }

  /// Preload TOTP codes for multiple secrets (useful for list views)
  void preloadTotpCodes(List<String> secrets, {int interval = _defaultInterval}) {
    for (final secret in secrets) {
      generateTotp(secret, interval: interval);
    }
  }

  /// Clear all cached entries
  void clearCache() {
    _cache.clear();
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final validEntries = _cache.values.where((entry) => entry.expiryTime.isAfter(now)).length;

    return {
      'total_entries': _cache.length,
      'valid_entries': validEntries,
      'expired_entries': _cache.length - validEntries,
    };
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
