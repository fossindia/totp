import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';

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

  /// Rotate encryption keys for enhanced security
  static Future<void> rotateKeys() async {
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
}
