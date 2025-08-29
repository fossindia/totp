import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/constants/strings.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({super.key, required this.onAuthenticated});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _getAvailableBiometrics();
    _authenticate(); // Automatically trigger authentication on load
  }

  Future<void> _checkBiometrics() async {
    try {
      await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      log(e.toString());
    }
    if (!mounted) {
      return;
    }
  }

  Future<void> _getAvailableBiometrics() async {
    try {
      await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      log(e.toString());
    }
    if (!mounted) {
      return;
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: AppStrings.biometricAuthentication,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException catch (e) {
      log(e.toString());
    }
    if (!mounted) {
      return;
    }

    if (authenticated) {
      log('Authenticated successfully!');
      widget
          .onAuthenticated(); // Call the callback on successful authentication
    } else {
      log('Authentication failed or cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system navigation bar and status bar colors to match Scaffold background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.darkGrey,
        statusBarColor: AppColors.darkGrey,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.darkGrey,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(flex: 2),
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.transparent,
                backgroundImage: const AssetImage('assets/images/logo.png'),
              ),
              const Spacer(flex: 1),
              const Text(
                AppStrings.unlockTotpAuthenticator,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                AppStrings.biometricAuthentication,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 16),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        8,
                      ), // Changed to a less rounded rectangle
                    ),
                  ),
                  child: const Text(
                    AppStrings.unlock,
                    style: TextStyle(fontSize: 18, color: AppColors.white),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
