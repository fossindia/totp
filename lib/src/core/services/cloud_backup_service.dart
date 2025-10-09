import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:totp/src/core/services/performance_monitor_service.dart';
import 'package:totp/src/core/utils/encryption_util.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

/// Cloud backup service for encrypted TOTP data storage
class CloudBackupService {
  static final CloudBackupService _instance = CloudBackupService._internal();
  factory CloudBackupService() => _instance;
  CloudBackupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Firebase is initialized in main.dart
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize cloud backup service: $e');
      rethrow;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Sign in anonymously for backup access
  Future<void> signInAnonymously() async {
    final timer = PerformanceTimer('Firebase Anonymous Sign In');

    try {
      await _auth.signInAnonymously();
      timer.finish(additionalMetadata: {'result': 'success'});
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Create encrypted backup of TOTP items
  Future<BackupResult> createBackup(
    List<TotpItem> items, {
    String? backupName,
    Map<String, dynamic>? metadata,
  }) async {
    final timer = PerformanceTimer('Cloud Backup Creation', {
      'item_count': items.length,
    });

    try {
      if (!isAuthenticated) {
        await signInAnonymously();
      }

      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create backup data structure
      final backupData = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'itemCount': items.length,
        'name':
            backupName ?? 'Backup ${DateTime.now().toString().split('.')[0]}',
        'deviceInfo': {'platform': defaultTargetPlatform.toString()},
        'metadata': metadata ?? {},
        'items': items.map((item) => item.toJson()).toList(),
      };

      // Encrypt the backup data
      final jsonData = jsonEncode(backupData);
      final encryptedData = EncryptionUtil.encrypt(jsonData);

      // Create backup document
      final backupDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .add({
            'name': backupData['name'],
            'timestamp': backupData['timestamp'],
            'itemCount': backupData['itemCount'],
            'version': backupData['version'],
            'size': encryptedData.length,
            'deviceInfo': backupData['deviceInfo'],
            'metadata': backupData['metadata'],
            'data': encryptedData, // Encrypted backup data
          });

      final result = BackupResult(
        id: backupDoc.id,
        name: backupData['name'] as String,
        timestamp: DateTime.parse(backupData['timestamp'] as String),
        itemCount: items.length,
        size: encryptedData.length,
      );

      timer.finish(
        additionalMetadata: {'result': 'success', 'backup_id': backupDoc.id},
      );
      return result;
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Restore from encrypted backup
  Future<List<TotpItem>> restoreBackup(String backupId) async {
    final timer = PerformanceTimer('Cloud Backup Restore', {
      'backup_id': backupId,
    });

    try {
      if (!isAuthenticated) {
        await signInAnonymously();
      }

      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get backup document
      final backupDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        throw Exception('Backup not found');
      }

      final data = backupDoc.data();
      if (data == null) {
        throw Exception('Backup data is empty');
      }

      // Decrypt backup data
      final encryptedData = data['data'] as String;
      final decryptedJson = EncryptionUtil.decrypt(encryptedData);

      // Parse backup data
      final backupData = jsonDecode(decryptedJson) as Map<String, dynamic>;
      final itemsJson = backupData['items'] as List<dynamic>;

      final items = itemsJson
          .map((item) => TotpItem.fromJson(item as Map<String, dynamic>))
          .toList();

      timer.finish(
        additionalMetadata: {
          'result': 'success',
          'restored_count': items.length,
        },
      );
      return items;
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// List all backups for current user
  Future<List<BackupInfo>> listBackups() async {
    final timer = PerformanceTimer('List Cloud Backups');

    try {
      if (!isAuthenticated) {
        await signInAnonymously();
      }

      final userId = currentUserId;
      if (userId == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .get();

      final backups = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return BackupInfo(
          id: doc.id,
          name: data['name'] as String,
          timestamp: DateTime.parse(data['timestamp'] as String),
          itemCount: data['itemCount'] as int,
          size: data['size'] as int,
          version: data['version'] as String,
        );
      }).toList();

      timer.finish(
        additionalMetadata: {
          'result': 'success',
          'backup_count': backups.length,
        },
      );
      return backups;
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      return [];
    }
  }

  /// Delete a backup
  Future<void> deleteBackup(String backupId) async {
    final timer = PerformanceTimer('Delete Cloud Backup', {
      'backup_id': backupId,
    });

    try {
      if (!isAuthenticated) {
        await signInAnonymously();
      }

      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .delete();

      timer.finish(additionalMetadata: {'result': 'success'});
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Get backup statistics
  Future<BackupStats> getBackupStats() async {
    final timer = PerformanceTimer('Get Backup Statistics');

    try {
      final backups = await listBackups();

      if (backups.isEmpty) {
        return BackupStats.empty();
      }

      final totalSize = backups.fold<int>(
        0,
        (total, backup) => total + backup.size,
      );
      final oldestBackup = backups.last.timestamp;
      final newestBackup = backups.first.timestamp;

      final stats = BackupStats(
        totalBackups: backups.length,
        totalSize: totalSize,
        oldestBackup: oldestBackup,
        newestBackup: newestBackup,
        averageSize: totalSize ~/ backups.length,
      );

      timer.finish(additionalMetadata: {'result': 'success'});
      return stats;
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      return BackupStats.empty();
    }
  }
}

/// Result of backup creation
class BackupResult {
  final String id;
  final String name;
  final DateTime timestamp;
  final int itemCount;
  final int size;

  const BackupResult({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.itemCount,
    required this.size,
  });

  @override
  String toString() {
    return 'BackupResult(id: $id, name: $name, items: $itemCount, size: $size)';
  }
}

/// Backup information for listing
class BackupInfo {
  final String id;
  final String name;
  final DateTime timestamp;
  final int itemCount;
  final int size;
  final String version;

  const BackupInfo({
    required this.id,
    required this.name,
    required this.timestamp,
    required this.itemCount,
    required this.size,
    required this.version,
  });

  @override
  String toString() {
    return 'BackupInfo(id: $id, name: $name, items: $itemCount, size: $size)';
  }
}

/// Backup statistics
class BackupStats {
  final int totalBackups;
  final int totalSize;
  final DateTime? oldestBackup;
  final DateTime? newestBackup;
  final int averageSize;

  const BackupStats({
    required this.totalBackups,
    required this.totalSize,
    this.oldestBackup,
    this.newestBackup,
    required this.averageSize,
  });

  factory BackupStats.empty() {
    return const BackupStats(totalBackups: 0, totalSize: 0, averageSize: 0);
  }

  @override
  String toString() {
    return 'BackupStats(backups: $totalBackups, totalSize: $totalSize, avgSize: $averageSize)';
  }
}
