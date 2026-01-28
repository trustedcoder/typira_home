import 'package:get/get.dart';
import '../api/scheduler_api.dart';
import '../constants/timezones.dart';

class Schedule {
  int? id;
  String title;
  String actionDescription;
  String timezone;
  String dateOrRepeat;
  bool isRepeat;
  String time;
  String? lastRun;

  Schedule({
    this.id,
    required this.title,
    this.actionDescription = "",
    this.timezone = "UTC",
    required this.dateOrRepeat,
    this.isRepeat = false,
    required this.time,
    this.lastRun,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      title: json['title'] ?? "",
      actionDescription: json['action_description'] ?? "",
      timezone: json['timezone'] ?? "UTC",
      dateOrRepeat: json['date_or_repeat'] ?? "",
      isRepeat: json['is_repeat'] ?? false,
      time: json['time'] ?? "",
      lastRun: json['last_run'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'action_description': actionDescription,
      'timezone': timezone,
      'date_or_repeat': dateOrRepeat,
      'is_repeat': isRepeat,
      'time': time,
    };
  }
}

class SchedulerController extends GetxController {
  final SchedulerApi _schedulerApi = SchedulerApi();
  var schedules = <Schedule>[].obs;
  var isLoading = false.obs;
  
  // Expose timezones from constants
  List<Map<String, String>> get availableTimezones => timezones;

  @override
  void onInit() {
    super.onInit();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    isLoading.value = true;
    try {
      final response = await _schedulerApi.getSchedules();
      if (response != null && response['data'] != null) {
        final List<dynamic> data = response['data'];
        schedules.assignAll(data.map((e) => Schedule.fromJson(e)).toList());
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load schedules: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSchedule(Schedule schedule) async {
    isLoading.value = true;
    try {
      final response = await _schedulerApi.createSchedule(schedule.toJson());
      if (response != null && response['status'] == 'success') {
        loadSchedules();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to add schedule: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSchedule(Schedule updatedSchedule) async {
    if (updatedSchedule.id == null) return;
    isLoading.value = true;
    try {
      final response = await _schedulerApi.updateSchedule(updatedSchedule.id!, updatedSchedule.toJson());
      if (response != null && response['status'] == 'success') {
        loadSchedules();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update schedule: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteSchedule(int id) async {
    isLoading.value = true;
    try {
      final response = await _schedulerApi.deleteSchedule(id);
      if (response != null && response['status'] == 'success') {
        schedules.removeWhere((s) => s.id == id);
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to delete schedule: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
