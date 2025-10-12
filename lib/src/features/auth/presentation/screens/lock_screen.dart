import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer';
import 'package:totp/src/core/constants/colors.dart';
import 'package:totp/src/core/constants/strings.dart';
import 'package:totp/src/core/services/auth_service.dart';
import 'package:totp/src/features/auth/presentation/widgets/pin_entry_dialog.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({super.key, required this.onAuthenticated});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authenticate(); // Automatically trigger authentication on load
  }

  Future<void> _authenticate() async {
    final result = await _authService.authenticateWithFallback(
      reason: AppStrings.biometricAuthentication,
    );

    if (!mounted) {
      return;
    }

    if (result.isSuccessful) {
      log('Authenticated successfully using ${result.method}!');
      widget
          .onAuthenticated(); // Call the callback on successful authentication
    } else if (result.pinRequired) {
      // Show PIN entry dialog
      await _showPinDialog();
    } else if (result.lockoutRemaining != null) {
      // Show lockout message
      await _showLockoutDialog(result.lockoutRemaining!);
    } else {
      log('Authentication failed: ${result.errorMessage}');
      // Optionally show error message to user
      await _showErrorDialog(result.errorMessage ?? 'Authentication failed');
    }
  }

  Future<void> _showPinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinEntryDialog(
        title: 'Enter PIN',
        subtitle: 'Enter your PIN to unlock the app',
        showBiometricOption: true,
        onBiometricPressed: () async {
          Navigator.of(context).pop(); // Close PIN dialog
          await _authenticate(); // Retry biometric
        },
      ),
    );

    if (result == true && mounted) {
      widget.onAuthenticated();
    }
  }

  Future<void> _showLockoutDialog(Duration remaining) async {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Too Many Attempts'),
        content: Text(
          'Too many failed authentication attempts. Please wait ${minutes}m ${seconds}s before trying again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
