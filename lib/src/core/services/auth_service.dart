import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/core/services/performance_monitor_service.dart';

class AuthService {
  final LocalAuthentication _localAuthentication;
  final FlutterSecureStorage _secureStorage;
  static const String _pinKey = 'user_pin';
  static const String _pinAttemptsKey = 'pin_attempts';
  static const String _pinLockoutKey = 'pin_lockout_until';
  static const int _maxPinAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  AuthService({
    LocalAuthentication? localAuthentication,
    FlutterSecureStorage? secureStorage,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

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
        localizedReason:
            'Please authenticate to enable biometric authentication',
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

  /// Enhanced authentication with biometric + PIN fallback
  Future<AuthResult> authenticateWithFallback({
    String? reason,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final timer = PerformanceTimer('Enhanced Authentication');

    try {
      // Check if device is locked out
      if (await _isLockedOut()) {
        final lockoutTime = await _getLockoutTimeRemaining();
        timer.finish(
          additionalMetadata: {
            'result': 'locked_out',
            'lockout_remaining': lockoutTime.inSeconds,
          },
        );
        return AuthResult.lockedOut(lockoutTime);
      }

      // Try biometric authentication first
      final biometricAvailable = await checkBiometrics();
      if (biometricAvailable) {
        final biometricSuccess = await _authenticateBiometric(
          reason: reason,
          timeout: timeout,
        );
        if (biometricSuccess) {
          await _resetPinAttempts();
          timer.finish(
            additionalMetadata: {
              'result': 'biometric_success',
              'method': 'biometric',
            },
          );
          return AuthResult.success(AuthMethod.biometric);
        }
      }

      // Fall back to PIN authentication
      final pinResult = await _authenticateWithPin();
      timer.finish(
        additionalMetadata: {
          'result': pinResult.isSuccessful ? 'pin_success' : 'pin_failed',
          'method': 'pin',
          'attempts_remaining': pinResult.attemptsRemaining,
        },
      );
      return pinResult;
    } catch (e) {
      timer.finish(
        additionalMetadata: {'result': 'error', 'error': e.toString()},
      );
      log('Authentication error: $e');
      return AuthResult.error('Authentication failed: $e');
    }
  }

  /// Set up PIN for fallback authentication
  Future<bool> setupPin(String pin) async {
    if (!_isValidPin(pin)) {
      return false;
    }

    try {
      await _secureStorage.write(key: _pinKey, value: pin);
      await _resetPinAttempts();
      return true;
    } catch (e) {
      log('Error setting up PIN: $e');
      return false;
    }
  }

  /// Check if PIN is set up
  Future<bool> hasPin() async {
    try {
      final pin = await _secureStorage.read(key: _pinKey);
      return pin != null && pin.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!_isValidPin(newPin)) {
      return false;
    }

    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin != oldPin) {
        return false;
      }

      await _secureStorage.write(key: _pinKey, value: newPin);
      await _resetPinAttempts();
      return true;
    } catch (e) {
      log('Error changing PIN: $e');
      return false;
    }
  }

  /// Clear PIN and reset authentication
  Future<void> clearPin() async {
    try {
      await _secureStorage.delete(key: _pinKey);
      await _resetPinAttempts();
    } catch (e) {
      log('Error clearing PIN: $e');
    }
  }

  /// Verify PIN (public method for UI components)
  Future<PinVerificationResult> verifyPin(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) {
        return PinVerificationResult.pinNotSetup();
      }

      if (storedPin == pin) {
        await _resetPinAttempts();
        return PinVerificationResult.success();
      } else {
        await _incrementPinAttempts();
        final attemptsRemaining = await _getAttemptsRemaining();

        if (attemptsRemaining <= 0) {
          return PinVerificationResult.lockedOut(
            await _getLockoutTimeRemaining(),
          );
        } else {
          return PinVerificationResult.failed(attemptsRemaining);
        }
      }
    } catch (e) {
      return PinVerificationResult.error('Error verifying PIN: $e');
    }
  }

  /// Get authentication status
  Future<AuthStatus> getAuthStatus() async {
    final hasBiometrics = await checkBiometrics();
    final hasPinSetup = await hasPin();
    final isLockedOut = await _isLockedOut();
    final attemptsRemaining = await _getAttemptsRemaining();

    return AuthStatus(
      biometricsAvailable: hasBiometrics,
      pinSetup: hasPinSetup,
      lockedOut: isLockedOut,
      attemptsRemaining: attemptsRemaining,
    );
  }

  // Private helper methods

  Future<bool> _authenticateBiometric({
    String? reason,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason ?? AppStrings.biometricAuthentication,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (e) {
      log('Biometric authentication error: ${e.message}');
      return false;
    }
  }

  Future<AuthResult> _authenticateWithPin() async {
    final storedPin = await _secureStorage.read(key: _pinKey);
    if (storedPin == null) {
      return AuthResult.pinNotSetup();
    }

    // In a real implementation, this would show a PIN entry dialog
    // For now, return that PIN authentication requires UI
    return AuthResult.pinRequired();
  }

  Future<bool> _isLockedOut() async {
    try {
      final lockoutStr = await _secureStorage.read(key: _pinLockoutKey);
      if (lockoutStr == null) return false;

      final lockoutTime = DateTime.parse(lockoutStr);
      return DateTime.now().isBefore(lockoutTime);
    } catch (e) {
      return false;
    }
  }

  Future<Duration> _getLockoutTimeRemaining() async {
    try {
      final lockoutStr = await _secureStorage.read(key: _pinLockoutKey);
      if (lockoutStr == null) return Duration.zero;

      final lockoutTime = DateTime.parse(lockoutStr);
      final remaining = lockoutTime.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      return Duration.zero;
    }
  }

  Future<int> _getAttemptsRemaining() async {
    try {
      final attemptsStr = await _secureStorage.read(key: _pinAttemptsKey);
      final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
      return _maxPinAttempts - attempts;
    } catch (e) {
      return _maxPinAttempts;
    }
  }

  Future<void> _incrementPinAttempts() async {
    try {
      final currentStr = await _secureStorage.read(key: _pinAttemptsKey);
      final current = int.tryParse(currentStr ?? '0') ?? 0;
      final newAttempts = current + 1;

      if (newAttempts >= _maxPinAttempts) {
        // Lock out the user
        final lockoutTime = DateTime.now().add(_lockoutDuration);
        await _secureStorage.write(
          key: _pinLockoutKey,
          value: lockoutTime.toIso8601String(),
        );
        await _secureStorage.write(key: _pinAttemptsKey, value: '0');
      } else {
        await _secureStorage.write(
          key: _pinAttemptsKey,
          value: newAttempts.toString(),
        );
      }
    } catch (e) {
      log('Error incrementing PIN attempts: $e');
    }
  }

  Future<void> _resetPinAttempts() async {
    try {
      await _secureStorage.delete(key: _pinAttemptsKey);
      await _secureStorage.delete(key: _pinLockoutKey);
    } catch (e) {
      log('Error resetting PIN attempts: $e');
    }
  }

  bool _isValidPin(String pin) {
    // PIN should be 4-8 digits
    return RegExp(r'^\d{4,8}$').hasMatch(pin);
  }
}

/// Authentication method used
enum AuthMethod { biometric, pin }

/// Result of authentication attempt
class AuthResult {
  final bool isSuccessful;
  final AuthMethod? method;
  final String? errorMessage;
  final Duration? lockoutRemaining;
  final int? attemptsRemaining;
  final bool pinRequired;
  final bool pinNotSetup;

  AuthResult._({
    required this.isSuccessful,
    this.method,
    this.errorMessage,
    this.lockoutRemaining,
    this.attemptsRemaining,
    this.pinRequired = false,
    this.pinNotSetup = false,
  });

  factory AuthResult.success(AuthMethod method) {
    return AuthResult._(isSuccessful: true, method: method);
  }

  factory AuthResult.failed(int attemptsRemaining) {
    return AuthResult._(
      isSuccessful: false,
      attemptsRemaining: attemptsRemaining,
    );
  }

  factory AuthResult.lockedOut(Duration remaining) {
    return AuthResult._(isSuccessful: false, lockoutRemaining: remaining);
  }

  factory AuthResult.error(String message) {
    return AuthResult._(isSuccessful: false, errorMessage: message);
  }

  factory AuthResult.pinRequired() {
    return AuthResult._(isSuccessful: false, pinRequired: true);
  }

  factory AuthResult.pinNotSetup() {
    return AuthResult._(isSuccessful: false, pinNotSetup: true);
  }
}

/// Authentication status
class AuthStatus {
  final bool biometricsAvailable;
  final bool pinSetup;
  final bool lockedOut;
  final int attemptsRemaining;

  const AuthStatus({
    required this.biometricsAvailable,
    required this.pinSetup,
    required this.lockedOut,
    required this.attemptsRemaining,
  });

  bool get canAuthenticate => biometricsAvailable || pinSetup;
  bool get needsSetup => !biometricsAvailable && !pinSetup;
}

/// PIN verification result
class PinVerificationResult {
  final bool isSuccessful;
  final String? errorMessage;
  final Duration? lockoutRemaining;
  final int? attemptsRemaining;
  final bool pinNotSetup;

  PinVerificationResult._({
    required this.isSuccessful,
    this.errorMessage,
    this.lockoutRemaining,
    this.attemptsRemaining,
    this.pinNotSetup = false,
  });

  factory PinVerificationResult.success() {
    return PinVerificationResult._(isSuccessful: true);
  }

  factory PinVerificationResult.failed(int attemptsRemaining) {
    return PinVerificationResult._(
      isSuccessful: false,
      attemptsRemaining: attemptsRemaining,
    );
  }

  factory PinVerificationResult.lockedOut(Duration remaining) {
    return PinVerificationResult._(
      isSuccessful: false,
      lockoutRemaining: remaining,
    );
  }

  factory PinVerificationResult.error(String message) {
    return PinVerificationResult._(isSuccessful: false, errorMessage: message);
  }

  factory PinVerificationResult.pinNotSetup() {
    return PinVerificationResult._(isSuccessful: false, pinNotSetup: true);
  }
}
