import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:totp/src/features/auth/presentation/screens/lock_screen.dart';
import 'package:totp/src/features/home/presentation/screens/home_screen.dart';

class AuthScreen extends StatelessWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, bypass authentication and directly go to home screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAuthenticated();
      });
      return HomeScreen(); // Return a placeholder or loading screen
    } else {
      return LockScreen(onAuthenticated: onAuthenticated);
    }
  }
}
