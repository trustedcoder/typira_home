import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../constants/app_theme.dart';
import '../controllers/splash.dart';

class SplashActivity extends StatelessWidget {

  const SplashActivity({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController());

    // Set the status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make the status bar transparent
      statusBarIconBrightness: Brightness
          .light, // Use light icons for dark backgrounds
    ));

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
          child: Container()
      ),
    );
  }

}
