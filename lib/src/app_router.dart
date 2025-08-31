import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:totp/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:totp/src/features/home/presentation/screens/home_screen.dart';
import 'package:totp/src/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:totp/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:totp/src/features/totp_management/presentation/screens/edit_account_screen.dart';
import 'package:totp/src/features/totp_management/models/totp_item.dart';

Future<GoRouter> createRouter(FlutterSecureStorage secureStorage) async {
  final String? biometricAuthEnabledString = await secureStorage.read(
    key: 'biometricAuthEnabled',
  );
  final bool biometricAuthEnabled = biometricAuthEnabledString == 'true';

  return GoRouter(
    initialLocation: biometricAuthEnabled ? '/' : '/home',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return AuthScreen(
            onAuthenticated: () {
              context.go('/home');
            },
          );
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return HomeScreen(key: UniqueKey());
        },
      ),
      GoRoute(
        path: '/qr_scanner',
        builder: (BuildContext context, GoRouterState state) {
          return const QRScannerScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: '/edit_account',
        builder: (BuildContext context, GoRouterState state) {
          final TotpItem totpItem = state.extra as TotpItem;
          return EditAccountScreen(totpItem: totpItem);
        },
      ),
    ],
  );
}
