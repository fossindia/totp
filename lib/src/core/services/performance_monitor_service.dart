import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitorService {
  static final PerformanceMonitorService _instance =
      PerformanceMonitorService._internal();
  factory PerformanceMonitorService() => _instance;
  PerformanceMonitorService._internal();

  final Map<String, _PerformanceMetric> _metrics = {};
  final StreamController<PerformanceEvent> _eventController =
      StreamController<PerformanceEvent>.broadcast();
  final List<PerformanceEvent> _events = []; // Store events for statistics
  bool _isEnabled = kDebugMode; // Only enabled in debug mode by default

  /// Stream of performance events
  Stream<PerformanceEvent> get events => _eventController.stream;

  /// Enable or disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if performance monitoring is enabled
  bool get isEnabled => _isEnabled;

  /// Start timing an operation
  String startTimer(String operationName, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return '';

    final timerId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    _metrics[timerId] = _PerformanceMetric(
      name: operationName,
      startTime: DateTime.now(),
      metadata: metadata,
    );

    return timerId;
  }

  /// End timing an operation and record the result
  void endTimer(String timerId, {Map<String, dynamic>? additionalMetadata}) {
    if (!_isEnabled || !_metrics.containsKey(timerId)) return;

    final metric = _metrics[timerId]!;
    final endTime = DateTime.now();
    final duration = endTime.difference(metric.startTime);

    final event = PerformanceEvent(
      type: PerformanceEventType.operation,
      name: metric.name,
      duration: duration,
      metadata: {...?metric.metadata, ...?additionalMetadata},
    );

    _eventController.add(event);
    _events.add(event); // Store for statistics
    _metrics.remove(timerId);

    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint(
        'Performance: ${metric.name} took ${duration.inMilliseconds}ms',
      );
    }
  }

  /// Record a performance event
  void recordEvent(
    String name,
    PerformanceEventType type, {
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) return;

    final event = PerformanceEvent(
      type: type,
      name: name,
      duration: duration,
      metadata: metadata,
    );

    _eventController.add(event);
    _events.add(event); // Store for statistics

    if (kDebugMode) {
      final durationStr = duration != null
          ? ' (${duration.inMilliseconds}ms)'
          : '';
      debugPrint('Performance Event: $name$durationStr');
    }
  }

  /// Record cache performance metrics
  void recordCacheMetrics(
    String cacheName, {
    required int hits,
    required int misses,
    required int totalRequests,
  }) {
    if (!_isEnabled) return;

    final hitRate = totalRequests > 0 ? hits / totalRequests : 0.0;

    recordEvent(
      '$cacheName Cache',
      PerformanceEventType.cache,
      metadata: {
        'hits': hits,
        'misses': misses,
        'total_requests': totalRequests,
        'hit_rate': hitRate,
      },
    );
  }

  /// Record memory usage metrics
  void recordMemoryUsage(String context, int bytesUsed) {
    if (!_isEnabled) return;

    recordEvent(
      'Memory Usage - $context',
      PerformanceEventType.memory,
      metadata: {
        'bytes_used': bytesUsed,
        'kb_used': bytesUsed / 1024,
        'mb_used': bytesUsed / (1024 * 1024),
      },
    );
  }

  /// Record UI rendering performance
  void recordUIRendering(String widgetName, Duration renderTime) {
    if (!_isEnabled) return;

    recordEvent(
      'UI Render - $widgetName',
      PerformanceEventType.ui,
      duration: renderTime,
    );
  }

  /// Record scroll performance metrics
  void recordScrollPerformance({
    required double scrollDistance,
    required Duration scrollTime,
    required int itemCount,
  }) {
    if (!_isEnabled) return;

    final itemsPerSecond = scrollTime.inSeconds > 0
        ? itemCount / scrollTime.inSeconds
        : 0.0;

    recordEvent(
      'Scroll Performance',
      PerformanceEventType.scroll,
      duration: scrollTime,
      metadata: {
        'scroll_distance': scrollDistance,
        'item_count': itemCount,
        'items_per_second': itemsPerSecond,
      },
    );
  }

  /// Get performance statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};

    // Group events by type
    final eventsByType = <PerformanceEventType, List<PerformanceEvent>>{};
    for (final event in _events) {
      eventsByType.putIfAbsent(event.type, () => []).add(event);
    }

    // Calculate statistics for each type
    for (final entry in eventsByType.entries) {
      final type = entry.key;
      final events = entry.value;

      if (events.isEmpty) continue;

      final durations = events
          .where((e) => e.duration != null)
          .map((e) => e.duration!.inMilliseconds)
          .toList();

      if (durations.isNotEmpty) {
        stats[type.toString()] = {
          'count': events.length,
          'avg_duration_ms':
              durations.reduce((a, b) => a + b) / durations.length,
          'min_duration_ms': durations.reduce((a, b) => a < b ? a : b),
          'max_duration_ms': durations.reduce((a, b) => a > b ? a : b),
        };
      } else {
        stats[type.toString()] = {'count': events.length};
      }
    }

    return stats;
  }

  /// Clear all metrics and events
  void clear() {
    _metrics.clear();
    _events.clear();
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
  }
}

/// Types of performance events
enum PerformanceEventType { operation, cache, memory, ui, scroll, network }

/// Performance event data class
class PerformanceEvent {
  final PerformanceEventType type;
  final String name;
  final Duration? duration;
  final Map<String, dynamic>? metadata;

  const PerformanceEvent({
    required this.type,
    required this.name,
    this.duration,
    this.metadata,
  });

  @override
  String toString() {
    final durationStr = duration != null
        ? ' (${duration!.inMilliseconds}ms)'
        : '';
    return 'PerformanceEvent($type: $name$durationStr)';
  }
}

/// Internal performance metric tracking
class _PerformanceMetric {
  final String name;
  final DateTime startTime;
  final Map<String, dynamic>? metadata;

  _PerformanceMetric({
    required this.name,
    required this.startTime,
    this.metadata,
  });
}

/// Convenience functions for easy performance monitoring
class PerformanceMonitor {
  static final PerformanceMonitorService _service = PerformanceMonitorService();

  /// Start timing an operation
  static String startTimer(
    String operationName, {
    Map<String, dynamic>? metadata,
  }) {
    return _service.startTimer(operationName, metadata: metadata);
  }

  /// End timing an operation
  static void endTimer(
    String timerId, {
    Map<String, dynamic>? additionalMetadata,
  }) {
    _service.endTimer(timerId, additionalMetadata: additionalMetadata);
  }

  /// Record a performance event
  static void recordEvent(
    String name,
    PerformanceEventType type, {
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) {
    _service.recordEvent(name, type, duration: duration, metadata: metadata);
  }

  /// Record cache metrics
  static void recordCacheMetrics(
    String cacheName, {
    required int hits,
    required int misses,
    required int totalRequests,
  }) {
    _service.recordCacheMetrics(
      cacheName,
      hits: hits,
      misses: misses,
      totalRequests: totalRequests,
    );
  }

  /// Record memory usage
  static void recordMemoryUsage(String context, int bytesUsed) {
    _service.recordMemoryUsage(context, bytesUsed);
  }

  /// Record UI rendering time
  static void recordUIRendering(String widgetName, Duration renderTime) {
    _service.recordUIRendering(widgetName, renderTime);
  }

  /// Record scroll performance
  static void recordScrollPerformance({
    required double scrollDistance,
    required Duration scrollTime,
    required int itemCount,
  }) {
    _service.recordScrollPerformance(
      scrollDistance: scrollDistance,
      scrollTime: scrollTime,
      itemCount: itemCount,
    );
  }

  /// Get performance statistics
  static Map<String, dynamic> getStatistics() {
    return _service.getStatistics();
  }

  /// Enable/disable monitoring
  static void setEnabled(bool enabled) {
    _service.setEnabled(enabled);
  }

  /// Clear all data
  static void clear() {
    _service.clear();
  }
}

/// Helper class for measuring execution time
class PerformanceTimer {
  final String operationName;
  final String _timerId;

  PerformanceTimer(this.operationName, [Map<String, dynamic>? metadata])
      : _timerId = PerformanceMonitor.startTimer(
            operationName,
            metadata: metadata,
          );

  void finish({Map<String, dynamic>? additionalMetadata}) {
    PerformanceMonitor.endTimer(
      _timerId,
      additionalMetadata: additionalMetadata,
    );
  }
}
