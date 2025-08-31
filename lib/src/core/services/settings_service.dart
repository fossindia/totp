import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsService {
  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;

  SettingsService() {
    _secureStorage = const FlutterSecureStorage();
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Copy TOTP on Tap
  bool getCopyTotpOnTap() {
    return _prefs.getBool('copyTotpOnTap') ?? true;
  }

  Future<void> setCopyTotpOnTap(bool value) async {
    await _prefs.setBool('copyTotpOnTap', value);
  }

  // TOTP Refresh Interval
  int getTotpRefreshInterval() {
    return _prefs.getInt('totpRefreshInterval') ?? 30;
  }

  Future<void> setTotpRefreshInterval(int value) async {
    await _prefs.setInt('totpRefreshInterval', value);
  }

  // Biometric Authentication
  Future<bool> getBiometricAuthEnabled() async {
    final String? biometricAuthEnabledString = await _secureStorage.read(
      key: 'biometricAuthEnabled',
    );
    return biometricAuthEnabledString == 'true';
  }

  Future<void> setBiometricAuthEnabled(bool value) async {
    await _secureStorage.write(key: 'biometricAuthEnabled', value: value.toString());
  }
}
