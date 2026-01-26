import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:typira/helpers/route.dart';

import '../controllers/dashboard.dart';
import 'logger.dart';

class AppHelper{
  /// This method is called when the user clicks on the local notification
  static void onMessageNotificationClicked(String payload) {
    logger.i("Notification clicked with payload: $payload");
    try {
      final Map<String, dynamic> data = json.decode(payload);
      if (data.containsKey('memory_id')) {
        String memoryId = data['memory_id'];
        Get.toNamed('/memory-detail', arguments: memoryId);
      }
    } catch (e) {
      logger.e("Error parsing notification payload: $e");
    }
  }

  /// This method is use to clear all states and return to the dashboard
  static void backToDashBoard(){
    if (Get.isRegistered<DashboardController>()) {
      Get.delete<DashboardController>();
    }
    RouteConfig.navigateToReplacePage('/dashboard');
  }

  static int getExtendedVersionNumber(String version) {
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 100000 + versionCells[1] * 1000 + versionCells[2];
  }

  static Color hexToColor(String hex) {
    hex = hex.toUpperCase().replaceAll("#", "").trim(); // Ensure no spaces or invalid characters
    if (hex.length == 6) {
      hex = "FF$hex"; // Add FF for full opacity if only RGB is provided
    }

    // Ensure valid hex length before parsing
    if (hex.length != 8) {
      return Color(0xff000000);
    }

    return Color(int.parse(hex, radix: 16));
  }

  static String getCurrencyNumber(int data) {
    return NumberFormat.compactCurrency(
      decimalDigits: 2,
      symbol: '',
    ).format(data);
  }
}