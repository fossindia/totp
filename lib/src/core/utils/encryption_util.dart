import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:totp/src/core/services/performance_monitor_service.dart';

class EncryptionUtil {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyStorageKey = 'encryption_key';
  static const String _ivStorageKey = 'encryption_iv';
  static const String _keyVersionKey = 'key_version';

  static Key? _key;
  static IV? _iv;
  static Encrypter? _encrypter;

  static Future<void> init() async {
    if (_key == null || _iv == null || _encrypter == null) {
      String? storedKey = await _secureStorage.read(key: _keyStorageKey);
      String? storedIv = await _secureStorage.read(key: _ivStorageKey);
      String? keyVersion = await _secureStorage.read(key: _keyVersionKey);

      if (storedKey == null || storedIv == null || keyVersion == null) {
        // Generate new cryptographically secure key and IV if not found
        _key = Key.fromSecureRandom(32);
        _iv = IV.fromSecureRandom(16);
        await _secureStorage.write(key: _keyStorageKey, value: _key!.base64);
        await _secureStorage.write(key: _ivStorageKey, value: _iv!.base64);
        await _secureStorage.write(key: _keyVersionKey, value: '1.0');
      } else {
        // Use stored key and IV
        _key = Key.fromBase64(storedKey);
        _iv = IV.fromBase64(storedIv);
      }
      _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
    }
  }

  static String encrypt(String plainText) {
    if (_encrypter == null || _key == null || _iv == null) {
      throw StateError('EncryptionUtil not initialized. Call init() first.');
    }

    try {
      // Generate a new IV for each encryption operation for enhanced security
      final iv = IV.fromSecureRandom(16);
      final Encrypted encrypted = _encrypter!.encrypt(plainText, iv: iv);

      // Combine IV and encrypted data for storage
      final combined = Uint8List(iv.bytes.length + encrypted.bytes.length);
      combined.setAll(0, iv.bytes);
      combined.setAll(iv.bytes.length, encrypted.bytes);

      return base64.encode(combined);
    } catch (e) {
      throw StateError('Encryption failed: ${e.toString().split(':').first}');
    }
  }

  static String decrypt(String encryptedText) {
    if (_encrypter == null || _key == null) {
      throw StateError('EncryptionUtil not initialized. Call init() first.');
    }

    try {
      final combined = base64.decode(encryptedText);

      // Extract IV and encrypted data
      final iv = IV(Uint8List.fromList(combined.take(16).toList()));
      final encryptedData = Encrypted(
        Uint8List.fromList(combined.skip(16).toList()),
      );

      return _encrypter!.decrypt(encryptedData, iv: iv);
    } catch (e) {
      throw StateError('Decryption failed: Invalid data or key');
    }
  }

  /// Rotate encryption keys for enhanced security (legacy method - use performKeyRotation for migration)
  @Deprecated('Use performKeyRotation() instead for better migration support')
  static Future<void> rotateKeys() async {
    // Generate new cryptographically secure key and IV
    final newKey = Key.fromSecureRandom(32);
    final newIv = IV.fromSecureRandom(16);

    // Update stored values
    await _secureStorage.write(key: _keyStorageKey, value: newKey.base64);
    await _secureStorage.write(key: _ivStorageKey, value: newIv.base64);
    await _secureStorage.write(
      key: _keyVersionKey,
      value: DateTime.now().toIso8601String(),
    );

    // Update in-memory values
    _key = newKey;
    _iv = newIv;
    _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
  }

  /// Validate if the stored key is still secure
  static Future<bool> validateKeySecurity() async {
    try {
      final testEncryption = encrypt('test');
      final testDecryption = decrypt(testEncryption);
      return testDecryption == 'test';
    } catch (e) {
      return false;
    }
  }

  /// Rotate encryption keys securely
  /// This generates new keys and provides a way to migrate existing data
  static Future<KeyRotationResult> performKeyRotation() async {
    final timer = PerformanceTimer('Key Rotation');

    try {
      // Store old keys for migration
      final oldKey = _key;
      final oldIv = _iv;
      final oldEncrypter = _encrypter;

      if (oldKey == null || oldIv == null || oldEncrypter == null) {
        throw StateError('EncryptionUtil not initialized. Call init() first.');
      }

      // Generate new cryptographically secure key and IV
      final newKey = Key.fromSecureRandom(32);
      final newIv = IV.fromSecureRandom(16);

      // Update stored values
      await _secureStorage.write(key: _keyStorageKey, value: newKey.base64);
      await _secureStorage.write(key: _ivStorageKey, value: newIv.base64);

      // Update in-memory values
      _key = newKey;
      _iv = newIv;
      _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));

      timer.finish(additionalMetadata: {'result': 'success'});

      return KeyRotationResult(
        oldKey: oldKey,
        oldIv: oldIv,
        oldEncrypter: oldEncrypter,
        newKey: newKey,
        newIv: newIv,
        newEncrypter: _encrypter!,
      );
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      rethrow;
    }
  }

  /// Migrate encrypted data from old keys to new keys
  static String migrateEncryptedData(
    String oldEncryptedData,
    KeyRotationResult rotation,
  ) {
    // Decrypt with old keys
    final combined = base64.decode(oldEncryptedData);
    final iv = IV(Uint8List.fromList(combined.take(16).toList()));
    final encryptedData = Encrypted(
      Uint8List.fromList(combined.skip(16).toList()),
    );
    final decryptedData = rotation.oldEncrypter.decrypt(encryptedData, iv: iv);

    // Re-encrypt with new keys
    final newIv = IV.fromSecureRandom(16);
    final newEncrypted = rotation.newEncrypter.encrypt(
      decryptedData,
      iv: newIv,
    );

    // Combine new IV and encrypted data
    final newCombined = Uint8List(
      newIv.bytes.length + newEncrypted.bytes.length,
    );
    newCombined.setAll(0, newIv.bytes);
    newCombined.setAll(newIv.bytes.length, newEncrypted.bytes);

    return base64.encode(newCombined);
  }

  /// Check if key rotation is recommended (based on key age)
  static Future<bool> shouldRotateKeys() async {
    try {
      final keyVersion = await _secureStorage.read(key: _keyVersionKey);
      if (keyVersion == null) return true; // No version means old key format

      // For now, recommend rotation every 90 days
      // In a real app, you might want more sophisticated logic
      final versionDate = DateTime.tryParse(keyVersion);
      if (versionDate == null) return true;

      final daysSinceRotation = DateTime.now().difference(versionDate).inDays;
      return daysSinceRotation > 90;
    } catch (e) {
      // If we can't check, err on the side of caution
      return true;
    }
  }

  /// Get key rotation status information
  static Future<KeyRotationStatus> getKeyRotationStatus() async {
    try {
      final keyVersion = await _secureStorage.read(key: _keyVersionKey);
      final shouldRotate = await shouldRotateKeys();

      return KeyRotationStatus(
        lastRotationDate: keyVersion != null
            ? DateTime.tryParse(keyVersion)
            : null,
        shouldRotate: shouldRotate,
        daysSinceLastRotation: keyVersion != null
            ? DateTime.now().difference(DateTime.parse(keyVersion)).inDays
            : null,
      );
    } catch (e) {
      return KeyRotationStatus(
        lastRotationDate: null,
        shouldRotate: true,
        daysSinceLastRotation: null,
      );
    }
  }
}

/// Result of a key rotation operation
class KeyRotationResult {
  final Key oldKey;
  final IV oldIv;
  final Encrypter oldEncrypter;
  final Key newKey;
  final IV newIv;
  final Encrypter newEncrypter;

  const KeyRotationResult({
    required this.oldKey,
    required this.oldIv,
    required this.oldEncrypter,
    required this.newKey,
    required this.newIv,
    required this.newEncrypter,
  });
}

/// Status information about key rotation
class KeyRotationStatus {
  final DateTime? lastRotationDate;
  final bool shouldRotate;
  final int? daysSinceLastRotation;

  const KeyRotationStatus({
    required this.lastRotationDate,
    required this.shouldRotate,
    required this.daysSinceLastRotation,
  });

  @override
  String toString() {
    if (lastRotationDate == null) {
      return 'Key rotation status: Never rotated, rotation recommended';
    }

    final days = daysSinceLastRotation ?? 0;
    final status = shouldRotate ? 'Rotation recommended' : 'Keys are current';

    return 'Key rotation status: Last rotated ${lastRotationDate!.toString().split(' ')[0]}, '
        '$days days ago, $status';
  }
}
