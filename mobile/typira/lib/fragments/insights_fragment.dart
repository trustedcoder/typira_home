import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import '../controllers/insights_controller.dart';
import '../constants/app_theme.dart';

class InsightsFragment extends StatelessWidget {
  const InsightsFragment({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InsightsController());

    return SafeArea(
      child: Obx(() {
        if (controller.isLoading.value && controller.activityData.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentColor));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.fetchInsights();
          },
          color: AppTheme.accentColor,
          backgroundColor: const Color(0xFF1E293B),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 100.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Agent Insights",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter'),
                ),
                SizedBox(height: 24.h),

                // Top Stats Row
                Row(
                  children: [
                    Expanded(
                        child: _buildStatCard(
                            "Time Saved",
                            "${controller.timeSavedMinutes.value}m",
                            Icons.timer,
                            AppTheme.accentColor)),
                    SizedBox(width: 16.w),
                    Expanded(
                        child: _buildStatCard(
                            "Focus Score",
                            "${controller.focusScore.value}",
                            Icons.center_focus_strong,
                            const Color(0xFF00E676))),
                  ],
                ),
                SizedBox(height: 16.h),
                _buildStatCard(
                    "Words Polished", "${controller.wordsPolished.value}",
                    Icons.auto_awesome, const Color(0xFFD500F9),
                    fullWidth: true),

                SizedBox(height: 32.h),
                Text("Bio-Digital Analysis (Beta)",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Text("Inferred from keyboard dynamics & sentiment.",
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
                SizedBox(height: 16.h),

                // Bio Stats Grid
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildBioCard(
                              "Current Mood",
                              controller.currentMood.value,
                              Icons.emoji_emotions,
                              Colors.amber,
                              subtitle: "Positive Sentiment"),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildBioCard(
                              "Stress Level",
                              "${controller.stressLevel.value}%",
                              Icons.speed,
                              Colors.lightBlueAccent,
                              subtitle: "Optimal Flow"),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBioCard(
                              "Energy Level",
                              controller.energyLevel.value,
                              Icons.bolt,
                              Colors.orangeAccent,
                              subtitle: "Typing Bursts"),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildBioCard(
                              "Tone Profile",
                              controller.toneProfile.value,
                              Icons.translate,
                              Colors.purpleAccent,
                              subtitle: "Vocabulary Analysis"),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 32.h),
                Text("Activity Trend",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 16.h),

                // Line Chart
                Container(
                  height: 200.h,
                  padding: EdgeInsets.only(right: 20.w, top: 10.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: controller.activityData.isEmpty
                      ? const Center(
                          child: Text("No activity data available",
                              style: TextStyle(color: Colors.white38)))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const days = [
                                          "M",
                                          "T",
                                          "W",
                                          "T",
                                          "F",
                                          "S",
                                          "S"
                                        ];
                                        if (value.toInt() >= 0 &&
                                            value.toInt() < days.length) {
                                          return Text(days[value.toInt()],
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 10.sp));
                                        }
                                        return const Text("");
                                      },
                                      interval: 1)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: controller.activityData,
                                isCurved: true,
                                color: AppTheme.accentColor,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.accentColor.withOpacity(0.1)),
                              ),
                            ],
                          ),
                        ),
                ),

                SizedBox(height: 32.h),
                Text("Interaction Modes",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 16.h),

                // Pie Chart
                Container(
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: controller.interactionModeData.isEmpty
                      ? const Center(
                          child: Text("No interaction data available",
                              style: TextStyle(color: Colors.white38)))
                      : Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sections: controller.interactionModeData,
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegendItem(
                                    const Color(0xFF00E5FF), "Vision"),
                                SizedBox(height: 8.h),
                                _buildLegendItem(
                                    const Color(0xFFD500F9), "Voice"),
                                SizedBox(height: 8.h),
                                _buildLegendItem(
                                    const Color(0xFF2979FF), "Text"),
                              ],
                            ),
                            SizedBox(width: 40.w),
                          ],
                        ),
                )
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24.sp),
              if (!fullWidth) Icon(Icons.arrow_upward, color: Colors.green, size: 16.sp), // Trend indicator
            ],
          ),
          SizedBox(height: 16.h),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
        ],
      ),
    );
  }

  Widget _buildBioCard(String title, String value, IconData icon, Color color, {String subtitle = ""}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              Spacer(),
              Icon(Icons.more_horiz, color: Colors.white24, size: 20.sp),
            ],
          ),
          SizedBox(height: 16.h),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(title, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(subtitle, style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12.w, height: 12.w, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        SizedBox(width: 8.w),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12.sp)),
      ],
    );
  }
}
