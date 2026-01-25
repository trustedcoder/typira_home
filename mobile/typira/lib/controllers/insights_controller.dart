import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/insights_api.dart';
import '../utils/color_utils.dart';

class InsightsController extends GetxController {
  final insightsApi = InsightsApi();
  
  // States
  var isLoading = false.obs;

  // Stats
  var timeSavedMinutes = 0.obs;
  var wordsPolished = 0.obs;
  var focusScore = 0.obs;
  
  // AI Keyboard Insights
  var currentMood = "".obs;
  var moodEmoji = "".obs;
  var moodColor = "".obs;
  var stressEmoji = "".obs;
  var stressConclusion = "".obs;
  var stressColor = "".obs;
  var energyEmoji = "".obs;
  var energyConclusion = "".obs;
  var energyColor = "".obs;
  var toneEmoji = "".obs;
  var toneConclusion = "".obs;
  var toneColor = "".obs;
  var stressLevel = 0.obs;
  var healthScore = 0.obs;
  var energyLevel = "".obs;
  var toneProfile = "".obs;
  var sentiment = "".obs;

  // Chart Data
  var activityData = <FlSpot>[].obs;
  var interactionModeData = <PieChartSectionData>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchInsights();
  }

  Future<void> fetchInsights() async {
    isLoading.value = true;
    try {
      final response = await insightsApi.getInsightsStats();
      if (response['status'] == 1) {
        final data = response['data'];
        timeSavedMinutes.value = data['timeSavedMinutes'];
        wordsPolished.value = data['wordsPolished'];
        focusScore.value = data['focusScore'];
        currentMood.value = data['currentMood'];
        moodEmoji.value = data['moodEmoji'];
        moodColor.value = data['moodColor'];
        stressEmoji.value = data['stressEmoji'];
        stressConclusion.value = data['stressConclusion'];
        stressColor.value = data['stressColor'];
        energyEmoji.value = data['energyEmoji'];
        energyConclusion.value = data['energyConclusion'];
        energyColor.value = data['energyColor'];
        toneEmoji.value = data['toneEmoji'];
        toneConclusion.value = data['toneConclusion'];
        toneColor.value = data['toneColor'];
        stressLevel.value = data['stressLevel'];
        healthScore.value = data['healthScore'];
        energyLevel.value = data['energyLevel'];
        toneProfile.value = data['toneProfile'];
        sentiment.value = data['sentiment'];

        // Map activity data
        activityData.value = (data['activityData'] as List)
            .map((spot) => FlSpot(spot['x'].toDouble(), spot['y'].toDouble()))
            .toList();

        // Map interaction mode data
        interactionModeData.value = (data['interactionModeData'] as List)
            .map((section) => PieChartSectionData(
                  color: ColorUtils.fromHex(section['color']),
                  value: section['value'].toDouble(),
                  title: '${section['value']}%',
                  radius: 25,
                  titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ))
            .toList();
      }
    } catch (e) {
      print("Error fetching insights: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
