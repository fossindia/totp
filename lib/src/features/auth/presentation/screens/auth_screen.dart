import 'package:flutter/material.dart';
import 'package:totp/src/features/auth/presentation/screens/lock_screen.dart';

class AuthScreen extends StatelessWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    return LockScreen(onAuthenticated: onAuthenticated);
  }
}
