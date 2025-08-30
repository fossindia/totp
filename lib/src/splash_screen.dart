import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:totp/src/core/constants/colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: AppColors.darkGrey,
        statusBarColor: AppColors.darkGrey,
        systemNavigationBarIconBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Directionality(
      textDirection: TextDirection.ltr, // Or TextDirection.rtl based on your app's primary direction
      child: Scaffold(
        backgroundColor: AppColors.darkGrey,
        body: Center(
          child: Image.asset(
            'assets/images/logo.png',
            width: 150, // Adjust size as needed
            height: 150, // Adjust size as needed
          ),
        ),
      ),
    );
  }
}
