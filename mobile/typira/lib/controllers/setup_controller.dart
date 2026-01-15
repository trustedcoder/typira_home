
import 'package:app_settings/app_settings.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typira/services/notification.dart';
import 'package:typira/storage/session_manager.dart';
import 'package:typira/helpers/route.dart';
import 'dart:io';

class SetupController extends GetxController {
  var currentPage = 0.obs;
  final pageController = PageController();
  
  // Track permission status if needed, or just rely on user action
  var isNotificationGranted = false.obs;

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void next() {
    if (currentPage.value < 1) { // 2 pages total, index 0 and 1
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      finishSetup();
    }
  }

  Future<void> requestNotificationPermission() async {
    // We reuse the service logic. 
    // It's void, so we just await it. 
    // Ideally we'd want to know if it was granted to update UI, but for now we just trigger it.
    await NotificationService.setupFirebaseMessaging();
    await NotificationService.setupLocalNotification();
    
    // Optimistically assume processed or let user click next.
    // In a real app we might check permission status again.
    next();
  }

  Future<void> openKeyboardSettings() async {
    if (Platform.isIOS) {
       // iOS specific: open settings to allow user to add keyboard
       await AppSettings.openAppSettings(type: AppSettingsType.settings);
    } else if (Platform.isAndroid) {
       // Android: Open Input Method settings
       // We can try a specific intent string if the wrapper doesn't support it directly, 
       // but typically 'settings' is too broad. 
       // Since 'inputMethod' was missing in the enum, we previously fell back to 'settings'.
       // We should verify if 'security' or 'device' or another type is closer, 
       // or use Platform Channel to invoke 'android.settings.INPUT_METHOD_SETTINGS'.
       // Note: app_settings: ^6.0.0 usually has 'inputMethod' but might be named differently or require cast.
       // Let's rely on standard 'settings' for now but if user said it opens App Info, that's what 'settings' does often.
       // We will try to use the specific 'android_intent_plus' or 'url_launcher' approach if app_settings fails us.
       // BUT wait, app_settings 6.0.0 DOES have settings, maybe I used the wrong enum name?
       // Let's try to see if we can use a raw string or check documentation.
       // Actually, I can use the 'url_launcher' to launch the intent action directly.
       final intent = AndroidIntent(
         action: 'android.settings.INPUT_METHOD_SETTINGS',
       );
       await intent.launch();
    }
  }
  
  Future<void> finishSetup() async {
    // Logic from IntroController's finishIntro
    SessionManager.setSeenIntro(true); // Ensure we mark intro/setup as done
    
    if(SessionManager.isLoggedIn()){
      RouteConfig.navigateToReplacePage("/home");
    }
    else{
      RouteConfig.navigateToReplacePage("/login");
    }
  }
}
