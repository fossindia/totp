import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:totp/src/core/constants/colors.dart' as core_colors;
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/app_router.dart';
import 'package:totp/src/splash_screen.dart';

class TotpApp extends StatefulWidget {
  const TotpApp({super.key});

  @override
  State<TotpApp> createState() => _TotpAppState();
}

class _TotpAppState extends State<TotpApp> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _setupRouter();
  }

  Future<void> _setupRouter() async {
    _router = await createRouter(_secureStorage);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return const SplashScreen();
    }
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
          primary: core_colors.AppColors.primaryPurple,
          onPrimary: core_colors.AppColors.white,
          secondary: core_colors.AppColors.teal,
          onSecondary: core_colors.AppColors.black,
          surface: core_colors.AppColors.darkGrey,
          onSurface: core_colors.AppColors.white,
          error: core_colors.AppColors.errorRed,
          onError: core_colors.AppColors.black,
          surfaceContainerHighest: core_colors.AppColors.surfaceContainer,
          onSurfaceVariant: core_colors.AppColors.white,
        ),
        useMaterial3: true,
      ),
      routerConfig: _router!,
      themeMode: ThemeMode.system,
    );
  }
}
