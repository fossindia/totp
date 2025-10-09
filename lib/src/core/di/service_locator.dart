import 'package:get_it/get_it.dart';
import 'package:totp/src/core/services/auth_service.dart';
import 'package:totp/src/core/services/settings_service.dart';
import 'package:totp/src/core/services/qr_code_processor_service.dart';
import 'package:totp/src/core/services/data_management_service.dart';
import 'package:totp/src/core/services/cloud_backup_service.dart';
import 'package:totp/src/core/utils/encryption_util.dart';
import 'package:totp/src/features/totp_management/totp_manager.dart';
import 'package:totp/src/features/totp_generation/totp_service.dart';

/// Service locator for dependency injection
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Register all services and dependencies
  static void setup() {
    // Core utilities (singletons)
    _getIt.registerLazySingleton<EncryptionUtil>(() => EncryptionUtil());

    // Core services (singletons)
    _getIt.registerLazySingleton<AuthService>(() => AuthService());
    _getIt.registerLazySingleton<SettingsService>(() => SettingsService());
    _getIt.registerLazySingleton<DataManagementService>(
      () => DataManagementService(),
    );
    _getIt.registerLazySingleton<CloudBackupService>(
      () => CloudBackupService(),
    );

    // TOTP related services
    _getIt.registerLazySingleton<TotpManager>(() => TotpManager());
    _getIt.registerLazySingleton<TotpService>(() => TotpService());

    // QR Code processing service (factory to allow for testing).
    // Use registerFactoryParam so callers can optionally provide a TotpManager
    // When setup() is called multiple times (e.g., in tests), avoid duplicate registrations.
    if (!_getIt.isRegistered<QrCodeProcessorService>()) {
      _getIt.registerFactoryParam<QrCodeProcessorService, TotpManager?, void>(
        (totpManager, _) => QrCodeProcessorService(
          totpManager: totpManager ?? _getIt<TotpManager>(),
        ),
      );
    }
  }

  /// Get a service instance
  static T get<T extends Object>() {
    try {
      return _getIt<T>();
    } catch (e) {
      throw StateError(
        'Service $T not registered. Call ServiceLocator.setup() first.',
      );
    }
  }

  /// Check if a service is registered
  static bool isRegistered<T extends Object>() {
    return _getIt.isRegistered<T>();
  }

  /// Register a service instance (for testing)
  static void register<T extends Object>(T instance) {
    _getIt.registerSingleton<T>(instance);
  }

  /// Register a factory (for testing)
  static void registerFactory<T extends Object>(FactoryFunc<T> factoryFunc) {
    _getIt.registerFactory<T>(factoryFunc);
  }

  /// Unregister all services (for testing)
  static void reset() {
    _getIt.reset();
  }

  /// Get all registered services (for debugging)
  static List<String> getRegisteredServices() {
    return [
      'TotpManager',
      'TotpService',
      'AuthService',
      'SettingsService',
      'QrCodeProcessorService',
      'CloudBackupService',
    ];
  }
}

/// Convenience extensions for easy service access
extension ServiceLocatorExtension on Object {
  T getService<T extends Object>() => ServiceLocator.get<T>();
}

/// Convenience function for getting services
T sl<T extends Object>() => ServiceLocator.get<T>();
