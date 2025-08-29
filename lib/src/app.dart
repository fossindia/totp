import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:totp/src/core/constants/colors.dart' as core_colors;
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/features/auth/presentation/screens/auth_screen.dart';
import 'package:totp/src/features/home/presentation/screens/home_screen.dart';
import 'package:totp/src/features/qr_scanner/presentation/screens/qr_scanner_screen.dart';
import 'package:totp/src/features/settings/presentation/screens/settings_screen.dart';
import 'package:totp/src/features/totp_management/presentation/screens/edit_account_screen.dart'; // Add this import
import 'package:totp/src/features/totp_management/models/totp_item.dart'; // Add this import

class TotpApp extends StatefulWidget {
  const TotpApp({super.key});

  @override
  State<TotpApp> createState() => _TotpAppState();
}

class _TotpAppState extends State<TotpApp> {
  // GoRouter configuration
  late final GoRouter _router = GoRouter(
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppStrings.totpAuthenticator,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: core_colors.AppColors.primaryPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: core_colors
              .AppColors
              .primaryPurple, // A vibrant purple for primary actions
          onPrimary: core_colors.AppColors.white,
          secondary: core_colors.AppColors.teal, // Teal for secondary elements
          onSecondary: core_colors.AppColors.black,
          surface:
              core_colors.AppColors.darkGrey, // Dark grey for general surfaces
          onSurface: core_colors.AppColors.white,
          error: core_colors.AppColors.errorRed, // Red for errors
          onError: core_colors.AppColors.black,
          surfaceContainerHighest: core_colors
              .AppColors
              .surfaceContainer, // Slightly lighter dark grey for variants
          onSurfaceVariant: core_colors.AppColors.white,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
      themeMode: ThemeMode.system,
    );
  }
}
