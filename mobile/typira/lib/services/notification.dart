import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:typira/helpers/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/user.dart';
import '../constants/app_config.dart';
import '../helpers/logger.dart';
import '../storage/session_manager.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if(Platform.isIOS){
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true, // Required to display a heads up notification
        badge: true,
        sound: true,
      );
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User denied permission');
    }

    // Listen for token refreshes
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print("FCM Token Refreshed: $newToken");
      updateFCMToken(newToken);
    });


    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null && message.notification?.android != null) {
        NotificationService.add(
            title: message.notification!.title!,
            body: message.notification!.body!,
            hasCode: message.notification.hashCode,
            payload: json.encode(message.data) // Pass the data here
        );
        print('Message also contained a notification: ${message.notification!.title}');
      }
      // Handle the received message
    });
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> setupLocalNotification() async {
    /// Setup the local notifications plugin
    /// Request local notifications permissions

    try {
      const InitializationSettings initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        ),
        macOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        ),
        linux: LinuxInitializationSettings(
          defaultActionName: 'Open notification')
      );
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          AppHelper.onMessageNotificationClicked(response.payload!);
        },
      );
      if(Platform.isIOS){
        final bool? result = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if(Platform.isMacOS){
        final bool? result = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      if(Platform.isAndroid){
        // Only request for Android 12 and above
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 31) {
          await requestAndroidNotificationPermissions();
        } else {
          print('Exact Alarms permission not required on this version.');
        }

      }
      logger.i("Local notification setup successfully");
    } catch (error, stackTrace) {
      logger.e(
        "Local notification setup failed",
        error: error,
        stackTrace: stackTrace,
      );
      // If the local notification setup fails, we can't continue
    }

    // Setup notification channels for android
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('typira_notification'),
      );
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
          channel
      );
      logger.i("Notification channels setup successfully");
    } catch (error, stackTrace) {
      logger.e(
        "Failed to setup notification channels",
        error: error,
        stackTrace: stackTrace,
      );
      // If the notification channel setup fails, we can't continue
    }

    // Setup firebase messaging notification permission
  }

  /// for flutter local notification (Android), you need to allow permission for notification and exact alarm
  static Future<void> requestAndroidNotificationPermissions() async {
    // Resolve platform-specific Android implementation
    final androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Request notification permissions
      final bool? notificationsPermissionGranted = await androidImplementation.requestNotificationsPermission();

      // if (notificationsPermissionGranted == true) {
      //   print('Notifications permission granted.');
      //
      //   // Request exact alarms permission (for Android 12+)
      //   final bool? exactAlarmsPermissionGranted = await androidImplementation.requestExactAlarmsPermission();
      //
      //   if (exactAlarmsPermissionGranted == true) {
      //     print('Exact Alarms permission granted.');
      //   } else {
      //     print('Exact Alarms permission denied.');
      //   }
      // } else {
      //   print('Notifications permission denied.');
      // }
    } else {
      print('Android implementation not available.');
    }
  }


  /// Adds a notification to the notification tray
  static Future<void> add({required String title, required String body, required int hasCode, String? payload}) async {
    await flutterLocalNotificationsPlugin.show(
      hasCode,
      title,
      body,
      NotificationDetails(
        iOS: const DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'channel_id',
          'channel_name',
          channelDescription: 'channel_description',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: payload ?? '{}'
    );
  }



  static Future<String?> getFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    if((Platform.isIOS || Platform.isMacOS) && kDebugMode){
      return await messaging.getAPNSToken();
    }
    try {
      return await messaging.getToken();
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateFCMToken(String fcmToken) async {
    final token = SessionManager.getAuth();
    String deviceName = await AppConfig.getDeviceName();
    try {
      final userApi = UserApi();
      userApi.updateUser(
          fcm_token: fcmToken,device_info: deviceName, token: token)
          .then((resp) {

      }, onError: (err) {

      });
    } catch (exception) {
      print(exception.toString());
    }
  }
}