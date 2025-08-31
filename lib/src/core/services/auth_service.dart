import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:totp/src/core/constants/strings.dart';

class AuthService {
  final LocalAuthentication _localAuthentication;

  AuthService({LocalAuthentication? localAuthentication})
      : _localAuthentication = localAuthentication ?? LocalAuthentication();

  Future<bool> checkBiometrics() async {
    try {
      return await _localAuthentication.canCheckBiometrics;
    } on PlatformException catch (e) {
      log('Error checking biometrics: ${e.message}');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuthentication.getAvailableBiometrics();
    } on PlatformException catch (e) {
      log('Error getting available biometrics: ${e.message}');
      return [];
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: AppStrings.biometricAuthentication,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException catch (e) {
      log('Error during authentication: ${e.message}');
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: 'Please authenticate to enable biometric authentication',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      log('Error during biometric authentication: ${e.message}');
      return false;
    }
  }
}
