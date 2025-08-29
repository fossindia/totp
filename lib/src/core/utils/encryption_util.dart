import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionUtil {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _keyStorageKey = 'encryption_key';
  static const String _ivStorageKey = 'encryption_iv';

  static Key? _key;
  static IV? _iv;
  static Encrypter? _encrypter;

  static Future<void> init() async {
    if (_key == null || _iv == null || _encrypter == null) {
      String? storedKey = await _secureStorage.read(key: _keyStorageKey);
      String? storedIv = await _secureStorage.read(key: _ivStorageKey);

      if (storedKey == null || storedIv == null) {
        // Generate new key and IV if not found
        _key = Key.fromLength(32);
        _iv = IV.fromLength(16);
        await _secureStorage.write(key: _keyStorageKey, value: _key!.base64);
        await _secureStorage.write(key: _ivStorageKey, value: _iv!.base64);
      } else {
        // Use stored key and IV
        _key = Key.fromBase64(storedKey);
        _iv = IV.fromBase64(storedIv);
      }
      _encrypter = Encrypter(AES(_key!, mode: AESMode.cbc));
    }
  }

  static String encrypt(String plainText) {
    if (_encrypter == null) {
      throw StateError('EncryptionUtil not initialized. Call init() first.');
    }
    final Encrypted encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
    return encrypted.base64;
  }

  static String decrypt(String encryptedText) {
    if (_encrypter == null) {
      throw StateError('EncryptionUtil not initialized. Call init() first.');
    }
    final Encrypted encrypted = Encrypted.fromBase64(encryptedText);
    return _encrypter!.decrypt(encrypted, iv: _iv!);
  }
}
