import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preference_app_group/shared_preference_app_group.dart';

class SessionManager {
  static SharedPreferences ?prefs;
  static const String keyIsSeenIntro = "isSeenIntro";
  static const String keyIsLoggedIn = "isLoggedIn";
  static const String keyAuth = "auth";
  static const String appGroupId = "group.com.typira.appdata";
  static const String keyUserName = "userName";

  static Future initSharedPrefrence() async {
    prefs = await SharedPreferences.getInstance();
    if (Platform.isIOS) {
      await SharedPreferenceAppGroup.setAppGroup(appGroupId);
      
      // Auto-sync token to App Group if already logged in
      String auth = getAuth();
      if (auth.isNotEmpty) {
        await SharedPreferenceAppGroup.setString("flutter.$keyAuth", auth);
      }
    }
  }

  static bool isSeenIntro() {
    return SessionManager.prefs!.getBool(keyIsSeenIntro) ?? false;
  }

  static void setSeenIntro(value) {
    SessionManager.prefs!.setBool(keyIsSeenIntro, value);
  }

  static bool isLoggedIn() {
    return SessionManager.prefs!.getBool(keyIsLoggedIn) ?? false;
  }

  static void setLoggedIn(value) {
    SessionManager.prefs!.setBool(keyIsLoggedIn, value);
  }

  static String getAuth() {
    return SessionManager.prefs!.getString(keyAuth) ?? "";
  }

  static void setAuth(value) {
    SessionManager.prefs!.setString(keyAuth, value);
    if (Platform.isIOS) {
      // Mirror to App Group for native Keyboard Extension access
      // Note: We use the 'flutter.' prefix to match SharedPreferences standard
      SharedPreferenceAppGroup.setString("flutter.$keyAuth", value);
    }
  }

  static String getUserName() {
    return SessionManager.prefs!.getString(keyUserName) ?? "";
  }

  static void setUserName(value) {
    SessionManager.prefs!.setString(keyUserName, value);
  }

  static void resetApp() {
    SessionManager.prefs!.clear();
    if (Platform.isIOS) {
      SharedPreferenceAppGroup.remove("flutter.$keyAuth");
    }
  }
}
