import 'package:flutter/material.dart';
import 'package:totp/src/core/di/service_locator.dart';
import 'package:totp/src/core/services/cloud_backup_service.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';

class CloudBackupScreen extends StatefulWidget {
  const CloudBackupScreen({super.key});

  @override
  State<CloudBackupScreen> createState() => _CloudBackupScreenState();
}

class _CloudBackupScreenState extends State<CloudBackupScreen> {
  late final CloudBackupService _backupService;
  late final TotpManager _totpManager;

  bool _isLoading = false;
  List<BackupInfo> _backups = [];
  BackupStats _stats = BackupStats.empty();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _backupService = getService<CloudBackupService>();
    _totpManager = getService<TotpManager>();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _backupService.initialize();
      _backups = await _backupService.listBackups();
      _stats = await _backupService.getBackupStats();
    } catch (e) {
      _errorMessage = 'Failed to load backup data: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createBackup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _totpManager.loadTotpItems();
      if (items.isEmpty) {
        setState(() {
          _errorMessage = 'No accounts to backup';
          _isLoading = false;
        });
        return;
      }

      final result = await _backupService.createBackup(items);
      await _loadData(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created: ${result.name}')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create backup: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will replace all your current accounts with the backup data. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _backupService.restoreBackup(backupId);
      await _totpManager.saveTotpItems(items);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored ${items.length} accounts from backup'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to restore backup: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _backupService.deleteBackup(backupId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup deleted')));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to delete backup: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),

                  // Statistics
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Backup Statistics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatRow(
                            'Total Backups',
                            _stats.totalBackups.toString(),
                          ),
                          _buildStatRow(
                            'Total Size',
                            _formatFileSize(_stats.totalSize),
                          ),
                          if (_stats.averageSize > 0)
                            _buildStatRow(
                              'Average Size',
                              _formatFileSize(_stats.averageSize),
                            ),
                          if (_stats.oldestBackup != null)
                            _buildStatRow(
                              'Oldest Backup',
                              _formatDateTime(_stats.oldestBackup!),
                            ),
                          if (_stats.newestBackup != null)
                            _buildStatRow(
                              'Latest Backup',
                              _formatDateTime(_stats.newestBackup!),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Create backup button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _createBackup,
                      icon: const Icon(Icons.backup),
                      label: const Text('Create New Backup'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Backups list
                  const Text(
                    'Available Backups',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_backups.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            'No backups found. Create your first backup above.',
                          ),
                        ),
                      ),
                    )
                  else
                    ..._backups.map(
                      (backup) => Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      backup.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'restore':
                                          _restoreBackup(backup.id);
                                          break;
                                        case 'delete':
                                          _deleteBackup(backup.id);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'restore',
                                        child: Text('Restore'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDateTime(backup.timestamp),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('${backup.itemCount} accounts'),
                                  const SizedBox(width: 16),
                                  Text(_formatFileSize(backup.size)),
                                  const SizedBox(width: 16),
                                  Text('v${backup.version}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Information card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About Cloud Backup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• All backups are encrypted end-to-end using AES-256\n'
                            '• Backups are stored securely in the cloud\n'
                            '• Only you can access your encrypted backups\n'
                            '• Restore will replace all current accounts\n'
                            '• Backups are anonymous and not linked to personal data',
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
