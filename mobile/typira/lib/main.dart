import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:typira/storage/session_manager.dart';

import 'activities/login_activity.dart';
import 'activities/register_activity.dart';
import 'activities/splash_activity.dart';
import 'activities/home_activity.dart';
import 'constants/app_theme.dart';
import 'controllers/life_cycle.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SessionManager.initSharedPrefrence();
  await ScreenUtil.ensureScreenSize();
  runApp(const ScreenSize());
}

class ScreenSize extends StatelessWidget {

  const ScreenSize({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LifeCycleController());
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context , child) {
        return const MyApp();
      },
    );
  }
}


class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print(SessionManager.getAuth());
    return GetMaterialApp(
      title: 'Typira',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      getPages: [
        GetPage(
          name: '/splash',
          page: () => const SplashActivity(),
          transition: Transition.rightToLeft,
          curve: Curves.easeInOut,
        ),
        GetPage(
          name: '/login',
          page: () => const LoginActivity(),
          transition: Transition.rightToLeft,
          curve: Curves.easeInOut,
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterActivity(),
          transition: Transition.rightToLeft,
          curve: Curves.easeInOut,
        ),
        GetPage(
          name: '/home',
          page: () => const HomeActivity(),
          transition: Transition.fadeIn,
          curve: Curves.easeInOut,
        ),
      ],
      initialRoute: '/splash',
    );
  }
}