import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // static const String baseUrl = "http://192.168.1.241:7009/api";
  // static const String socketUrl = "http://192.168.1.241:7009";

  static const String baseUrl = "https://typira.celestineobi.com/api";
  static const String socketUrl = "https://typira.celestineobi.com";
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";
  static const String getUser = "$baseUrl/user/me";
  static const String getInsightsStats = "$baseUrl/insights/stats";
  static const String getMemories = "$baseUrl/memory/memories";
  static const String getTypingHistory = "$baseUrl/memory/typing-history";
  static const String getUserActions = "$baseUrl/memory/user-actions";
  static const String scheduler = "$baseUrl/scheduler/";
  static const String delete_account = "$baseUrl/user/me";
  static const String clear_memory = "$baseUrl/memory/clear";



  static Future<String> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceName = '';

    try {
      if(kIsWeb){
        WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
        deviceName = webBrowserInfo.userAgent!;
      }
      else {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
          deviceName = '${androidInfo.device} || ${androidInfo.model} || ${androidInfo.product}';
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
          deviceName = '${iosInfo.systemName} || ${iosInfo.name} || ${iosInfo.model}';
        }
        else if (Platform.isMacOS) {
          MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
          deviceName =  '${macInfo.computerName} || ${macInfo.hostName} || ${macInfo.model}';
        }
        else if (Platform.isWindows) {
          WindowsDeviceInfo windowInfo = await deviceInfo.windowsInfo;
          deviceName =  '${windowInfo.computerName} || ${windowInfo.userName} || ${windowInfo.registeredOwner} || ${windowInfo.productName}';
        }
        else if (Platform.isLinux) {
          LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
          deviceName =  '${linuxInfo.name} || ${linuxInfo.prettyName} || ${linuxInfo.machineId}';
        }
      }
    } catch (e) {
      print("Error getting device ID: $e");
    }

    return deviceName;
  }
}