import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_theme.dart';
import '../storage/session_manager.dart';
import '../api/authentication.dart';

class SettingsActivity extends StatelessWidget {
  const SettingsActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Settings",
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
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        children: [
          _buildSettingsItem(
            icon: Icons.schedule,
            title: "Scheduler",
            subtitle: "Manage your AI assistant notifications",
            onTap: () => Get.toNamed("/scheduler"),
          ),
          SizedBox(height: 16.h),
          _buildSettingsItem(
            icon: Icons.cleaning_services,
            title: "Clear AI Memory",
            subtitle: "Wipe learned style and typing history",
            onTap: () => _handleClearMemory(),
          ),
          SizedBox(height: 16.h),
          _buildSettingsItem(
            icon: Icons.logout,
            title: "Logout",
            subtitle: "Sign out of your account",
            isDestructive: true,
            onTap: () => _handleLogout(),
          ),
          SizedBox(height: 16.h),
          _buildSettingsItem(
            icon: Icons.delete_forever,
            title: "Delete Account",
            subtitle: "Permanently delete your account and all data",
            isDestructive: true,
            onTap: () => _handleDeleteAccount(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
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
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: (isDestructive ? Colors.red : AppTheme.accentColor).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AppTheme.accentColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white24,
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to log out?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              SessionManager.resetApp();
              Get.offAllNamed("/login");
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Account", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This action is permanent and cannot be undone. All your data, including AI memory and history, will be permanently deleted.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              _performDelete();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _performDelete() async {
    final Authentication authApi = Authentication();
    
    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
      barrierDismissible: false,
    );

    try {
      final resp = await authApi.deleteAccount();
      Get.back(); // Remove loading

      if (resp['status'] == 1) {
        SessionManager.resetApp();
        Get.offAllNamed("/login");
        Get.snackbar(
          "Success",
          "Your account has been deleted.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Error",
          resp['message'] ?? "Could not delete account.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back(); // Remove loading
      Get.snackbar(
        "Error",
        "Connection error. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _handleClearMemory() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Clear AI Memory", style: TextStyle(color: Colors.white)),
        content: const Text(
          "This will permanently delete your typing history, learned writing style, and agent memory. Your account will remain active. Proceed?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              _performMemoryClear();
            },
            child: const Text("Clear", style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );
  }

  void _performMemoryClear() async {
    final Authentication authApi = Authentication();
    
    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppTheme.accentColor)),
      barrierDismissible: false,
    );

    try {
      final resp = await authApi.clearMemory();
      Get.back(); // Remove loading

      if (resp['status'] == 1) {
        Get.snackbar(
          "Success",
          "AI memory has been cleared.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Error",
          resp['message'] ?? "Could not clear memory.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.back(); // Remove loading
      Get.snackbar(
        "Error",
        "Connection error. Please try again.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
