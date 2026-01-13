import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static SharedPreferences ?prefs;
  static const String keyIsSeenIntro = "isSeenIntro";
  static const String keyIsLoggedIn = "isLoggedIn";
  static const String keyAuth = "auth";

  static Future initSharedPrefrence() async {
    prefs = await SharedPreferences.getInstance();
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
  }

  static void resetApp() {
    SessionManager.prefs!.clear();
  }
}
