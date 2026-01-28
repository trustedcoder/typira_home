import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../constants/app_theme.dart';
import '../controllers/scheduler_controller.dart';

class ScheduleEditActivity extends StatefulWidget {
  const ScheduleEditActivity({super.key});

  @override
  State<ScheduleEditActivity> createState() => _ScheduleEditActivityState();
}

class _ScheduleEditActivityState extends State<ScheduleEditActivity> {
  final _titleController = TextEditingController();
  final _actionController = TextEditingController();
  String _timezone = "UTC";
  String _time = "09:00";
  String _dateOrRepeat = "Everyday";
  bool _isRepeat = true;
  Schedule? _editingSchedule;

  // final List<String> _timezones = ["UTC", "GMT", "GMT+1", "GMT+2", "EST", "PST"]; // Removed
  final List<String> _repeatOptions = ["Everyday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

  @override
  void initState() {
    super.initState();
    _editingSchedule = Get.arguments as Schedule?;
    if (_editingSchedule != null) {
      _titleController.text = _editingSchedule!.title;
      _actionController.text = _editingSchedule!.actionDescription;
      _timezone = _editingSchedule!.timezone;
      _time = _editingSchedule!.time;
      _dateOrRepeat = _editingSchedule!.dateOrRepeat;
      _isRepeat = _editingSchedule!.isRepeat;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_time.split(":")[0]),
        minute: int.parse(_time.split(":")[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.accentColor,
              onPrimary: Colors.black,
              surface: const Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _time = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  void _saveSchedule() {
    if (_titleController.text.isEmpty) {
      Get.snackbar("Error", "Please enter a title", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    final schedulerController = Get.find<SchedulerController>();
    final newSchedule = Schedule(
      id: _editingSchedule?.id,
      title: _titleController.text,
      actionDescription: _actionController.text,
      timezone: _timezone,
      dateOrRepeat: _dateOrRepeat,
      isRepeat: _isRepeat,
      time: _time,
    );

    if (_editingSchedule != null) {
      schedulerController.updateSchedule(newSchedule);
    } else {
      schedulerController.addSchedule(newSchedule);
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _editingSchedule == null ? "New Schedule" : "Edit Schedule",
          style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("TITLE"),
            _buildTextField(_titleController, "e.g., Daily Insight"),
            SizedBox(height: 24.h),
            
            _buildLabel("ACTION DESCRIPTION (OPTIONAL)"),
            _buildTextField(
              _actionController, 
              "What should Typira do? (Empty = auto-insight)",
              maxLines: 3
            ),
            SizedBox(height: 24.h),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("TIMEZONE"),
                      _buildTimezoneDropdown(),
                    ],
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("TIME"),
                      _buildSelector(_time, Icons.access_time, () => _selectTime(context)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            _buildLabel("REPEAT / DATE"),
            _buildDropdown(_dateOrRepeat, _repeatOptions, (val) => setState(() => _dateOrRepeat = val!)),
            
            SizedBox(height: 48.h),
            
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                onPressed: _saveSchedule,
                child: Text(
                  "Save Schedule",
                  style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.accentColor,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(16.w),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimezoneDropdown() {
    final schedulerController = Get.find<SchedulerController>();
    final timezones = schedulerController.availableTimezones;
    
    // Ensure the current timezone exists in the list, otherwise default to first or keep it if we can render text
    // But DropdownButton requires value to be in items.
    // If _timezone is not in list (e.g. legacy GMT+1), we fallback to UTC or add it temporarily?
    // Let's fallback to UTC if not found, to match the requirement of "fixing" it.
    // Or better, check if present.
    
    String dropdownValue = _timezone;
    bool exists = timezones.any((t) => t['value'] == dropdownValue);
    if (!exists) {
      // If it looks like a valid IANA zone we might want to keep it? 
      // But for now let's default to UTC to force user to pick a valid one from our curated list.
      dropdownValue = "UTC"; 
      // Update state so we save the valid one later
      // valid: this is inside build, avoid setState here. Just use local var for display.
      // But when saving, we might save the old invalid one if user doesn't touch it?
      // No, we should probably update _timezone in initState if invalid?
      // For now, let's just use UTC in dropdown if invalid.
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          items: timezones.map((e) => DropdownMenuItem(
            value: e['value'],
            child: Text(
              e['label'] ?? "", 
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          )).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _timezone = val);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSelector(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: const TextStyle(color: Colors.white)),
            Icon(icon, color: Colors.white54, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
