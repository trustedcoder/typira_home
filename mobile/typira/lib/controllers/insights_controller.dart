import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class InsightsController extends GetxController {
  
  // Stats
  var timeSavedMinutes = 340.obs;
  var wordsPolished = 12500.obs;
  var focusScore = 88.obs;
  
  // AI Keyboard Insights
  var currentMood = "Energetic".obs; // Inferred from sentiment
  var stressLevel = 12.obs; // Low stress (0-100), inferred from typo rate/backspacing
  var healthScore = 94.obs; // Digital Wellbeing score
  var energyLevel = "High Voltage".obs; // Typing speed bursts
  var toneProfile = "Professional".obs; // Vocabulary analysis

  // Chart Data
  List<FlSpot> get activityData => [
    FlSpot(0, 3),
    FlSpot(1, 4),
    FlSpot(2, 3.5),
    FlSpot(3, 5),
    FlSpot(4, 8), // Peak productivity
    FlSpot(5, 6),
    FlSpot(6, 7),
  ];

  // Pie Data (Interaction Modes)
  List<PieChartSectionData> get interactionModeData => [
    PieChartSectionData(color: const Color(0xFF00E5FF), value: 40, title: '40%', radius: 25, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)), // Vision
    PieChartSectionData(color: const Color(0xFFD500F9), value: 35, title: '35%', radius: 25, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)), // Voice
    PieChartSectionData(color: const Color(0xFF2979FF), value: 25, title: '25%', radius: 25, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)), // Text
  ];
}
