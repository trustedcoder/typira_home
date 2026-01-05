import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color(0xff0A345a);
  static const Color accentColor = Color(0xffEEA525);
  static const Color whiteColor = Color(0xffffffff);
  static const Color blackColor = Color(0xff000000);
  static const Color grayColor = Color(0xff808b97);
  static const Color textColor = Color(0xff00162e);
  static const Color lightGrayColor = Color(0xfff5f6f7);
  static const Color buttonColor = Color(0xffffd600);
  static const Color greenColor = Color(0xff27af4d);

  // Logo
  static const String logo = 'assets/images/logo.png'; // Placeholder

  // Typography
  static TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: 'DMSans', fontSize: 24.sp, fontWeight: FontWeight.bold, color: textColor),
    displayMedium: TextStyle(fontFamily: 'DMSans', fontSize: 22.sp, fontWeight: FontWeight.bold, color: textColor),
    displaySmall: TextStyle(fontFamily: 'DMSans', fontSize: 20.sp, fontWeight: FontWeight.bold, color: textColor),
    headlineMedium: TextStyle(fontFamily: 'DMSans', fontSize: 18.sp, fontWeight: FontWeight.bold, color: textColor),
    headlineSmall: TextStyle(fontFamily: 'DMSans', fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
    titleLarge: TextStyle(fontFamily: 'DMSans', fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor),
    titleMedium: TextStyle(fontFamily: 'DMSans', fontSize: 14.sp, fontWeight: FontWeight.w600, color: textColor),
    titleSmall: TextStyle(fontFamily: 'DMSans', fontSize: 14.sp, fontWeight: FontWeight.w600, color: textColor),
    bodyLarge: TextStyle(fontFamily: 'DMSans', fontSize: 16.sp, color: textColor),
    bodyMedium: TextStyle(fontFamily: 'DMSans', fontSize: 14.sp, color: textColor),
    bodySmall: TextStyle(fontFamily: 'DMSans', fontSize: 12.sp, color: grayColor),
    labelSmall: TextStyle(fontFamily: 'DMSans', fontSize: 12.sp,fontWeight: FontWeight.w600, color: blackColor),
  );

  // Button Theme
  static final ButtonThemeData buttonTheme = ButtonThemeData(
    buttonColor: primaryColor,
    textTheme: ButtonTextTheme.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8.w),
    ),
  );

  static ThemeData get themeData {
    return ThemeData(
      primaryColor: primaryColor,
      hintColor: accentColor,
      scaffoldBackgroundColor: whiteColor,
      textTheme: textTheme,
      buttonTheme: buttonTheme,
      appBarTheme: const AppBarTheme(
        color: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: whiteColor),
      ),
    );
  }
}
