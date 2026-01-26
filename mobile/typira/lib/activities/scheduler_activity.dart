import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_theme.dart';
import '../controllers/scheduler_controller.dart';

class SchedulerActivity extends StatelessWidget {
  const SchedulerActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchedulerController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Scheduler",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
        }

        if (controller.schedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 80.sp, color: Colors.white10),
                SizedBox(height: 16.h),
                Text(
                  "No schedules yet",
                  style: TextStyle(color: Colors.white24, fontSize: 16.sp),
                ),
                SizedBox(height: 20.h),
                TextButton(
                  onPressed: () => controller.loadSchedules(),
                  child: const Text("Refresh", style: TextStyle(color: AppTheme.accentColor)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadSchedules(),
          color: AppTheme.accentColor,
          backgroundColor: const Color(0xFF1E293B),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            itemCount: controller.schedules.length,
            itemBuilder: (context, index) {
              final schedule = controller.schedules[index];
              return _buildScheduleCard(schedule, controller);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        onPressed: () => Get.toNamed("/schedule_edit"),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildScheduleCard(Schedule schedule, SchedulerController controller) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                schedule.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.white54, size: 20.sp),
                    onPressed: () => Get.toNamed("/schedule_edit", arguments: schedule),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red.withOpacity(0.5), size: 20.sp),
                    onPressed: () {
                      if (schedule.id != null) {
                        _confirmDelete(schedule.id!, controller);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            schedule.actionDescription.isEmpty 
              ? "Typira will find something insightful for you." 
              : schedule.actionDescription,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.accentColor, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                "${schedule.time} • ${schedule.dateOrRepeat}",
                style: TextStyle(color: AppTheme.accentColor, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                schedule.timezone,
                style: TextStyle(color: Colors.white24, fontSize: 12.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, SchedulerController controller) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Schedule", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this schedule?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteSchedule(id);
              Get.back();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
