import 'package:flutter/material.dart';
import 'package:totp/src/core/services/performance_monitor_service.dart';

class PerformanceDashboard extends StatefulWidget {
  const PerformanceDashboard({super.key});

  @override
  State<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends State<PerformanceDashboard> {
  Map<String, dynamic> _stats = {};
  bool _isMonitoringEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    setState(() {
      _stats = PerformanceMonitor.getStatistics();
      _isMonitoringEnabled = PerformanceMonitorService().isEnabled;
    });
  }

  void _toggleMonitoring(bool enabled) {
    PerformanceMonitor.setEnabled(enabled);
    setState(() {
      _isMonitoringEnabled = enabled;
    });
  }

  void _clearStats() {
    PerformanceMonitor.clear();
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh stats',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearStats,
            tooltip: 'Clear stats',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monitoring Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Performance Monitoring',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Enable monitoring:'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isMonitoringEnabled,
                          onChanged: _toggleMonitoring,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isMonitoringEnabled
                          ? 'Performance monitoring is active'
                          : 'Performance monitoring is disabled',
                      style: TextStyle(
                        color: _isMonitoringEnabled
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Performance Statistics
            if (_stats.isNotEmpty) ...[
              const Text(
                'Performance Statistics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Display stats for each event type
              ..._stats.entries.map((entry) {
                final eventType = entry.key;
                final stats = entry.value as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eventType,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (stats.containsKey('count'))
                          _buildStatRow('Events', stats['count'].toString()),
                        if (stats.containsKey('avg_duration_ms'))
                          _buildStatRow(
                            'Avg Duration',
                            '${stats['avg_duration_ms'].toStringAsFixed(2)}ms',
                          ),
                        if (stats.containsKey('min_duration_ms'))
                          _buildStatRow(
                            'Min Duration',
                            '${stats['min_duration_ms']}ms',
                          ),
                        if (stats.containsKey('max_duration_ms'))
                          _buildStatRow(
                            'Max Duration',
                            '${stats['max_duration_ms']}ms',
                          ),
                        if (stats.containsKey('hits'))
                          _buildStatRow('Cache Hits', stats['hits'].toString()),
                        if (stats.containsKey('misses'))
                          _buildStatRow(
                            'Cache Misses',
                            stats['misses'].toString(),
                          ),
                        if (stats.containsKey('hit_rate'))
                          _buildStatRow(
                            'Hit Rate',
                            '${(stats['hit_rate'] * 100).toStringAsFixed(1)}%',
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ] else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No performance data available.\nEnable monitoring and use the app to collect statistics.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'About Performance Monitoring',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This dashboard shows performance metrics collected during app usage. '
                      'Monitoring is automatically disabled in production builds.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Monitored operations include:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• TOTP code generation\n'
                      '• Cache operations\n'
                      '• UI rendering\n'
                      '• Scroll performance\n'
                      '• Background processing',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
