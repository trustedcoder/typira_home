import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_theme.dart';
import '../controllers/home.dart';
import '../controllers/home_input.dart';
import '../packages/sliding_up_panel/sliding_up_panel.dart';
import '../packages/sliding_up_panel/sliding_up_panel.dart';
import '../fragments/memory_fragment.dart';
import '../fragments/insights_fragment.dart';
import 'rewrite_activity.dart'; // Import Rewrite Activity

class HomeActivity extends StatelessWidget {
  const HomeActivity({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controllers
    final controller = Get.put(HomeController());
    final inputController = Get.put(HomeInputController());
    
    // Ensure dark mode for agent feel
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Agent Blue/Black
      
      body: SlidingUpPanel(
        controller: Get.find<HomeInputController>().panelController,
        minHeight: 0,
        maxHeight: 600.h,
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30.r), topRight: Radius.circular(30.r)),
        backdropEnabled: true,
        backdropColor: Colors.black,
        backdropOpacity: 0.8,
        panel: Obx(() => _buildPanelContent(context)),
        body: Obx(() => IndexedStack(
          index: controller.tabIndex.value,
          children: [
            _buildHomeTab(context, controller),
            const MemoryFragment(),
            const InsightsFragment(),
          ],
        )),
      ),

      // Bottom Navigation
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: controller.tabIndex.value,
          onTap: (index) => controller.tabIndex.value = index,
          backgroundColor: const Color(0xFF0F172A),
          selectedItemColor: AppTheme.accentColor,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "Memory"),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Insights"),
          ],
        ),
      )),
    );
  }

  // --- Tabs ---

  Widget _buildHomeTab(BuildContext context, HomeController controller) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Obx(() => _buildHeader(context, controller)),
              SizedBox(height: 40.h),
              Obx(() => _buildAgentCore(context, controller)),
              SizedBox(height: 40.h),
              Obx(() => _buildDialogueBox(context, controller)),
              SizedBox(height: 40.h),
              _buildInputChannels(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryTab() {
    return const MemoryFragment();
  }

  Widget _buildInsightsTab() {
    return const InsightsFragment();
  }

  Widget _buildHeader(BuildContext context, HomeController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning, Celestine", // Dynamic name later
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter', // Assuming standard font
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8.w, height: 8.w,
                  decoration: BoxDecoration(
                    color: controller.isOffline.value ? Colors.red : AppTheme.primaryColor,
                    shape: BoxShape.circle
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  controller.isOffline.value ? "System Offline" : "System Online • Ready",
                  style: TextStyle(
                    color: controller.isOffline.value ? Colors.red : AppTheme.primaryColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            // Toggle offline mode for demo
            controller.isOffline.value = !controller.isOffline.value;
          }, 
          icon: Icon(Icons.settings, color: Colors.white54)
        )
      ],
    );
  }

  Widget _buildAgentCore(BuildContext context, HomeController controller) {
    bool offline = controller.isOffline.value;
    bool thinking = controller.isThinking.value;

    return Center(
      child: Container(
        width: 200.w,
        height: 200.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              offline ? Colors.grey.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: [0.3, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: offline ? Colors.transparent : (thinking ? AppTheme.accentColor.withOpacity(0.6) : AppTheme.primaryColor.withOpacity(0.5)),
                  blurRadius: offline ? 0 : (thinking ? 30 : 20),
                  spreadRadius: offline ? 0 : (thinking ? 5 : 2),
                )
              ],
              border: Border.all(
                color: offline ? Colors.grey.withOpacity(0.3) : AppTheme.primaryColor.withOpacity(0.5), 
                width: 1
              ),
            ),
            child: Icon(
              offline ? Icons.power_off : Icons.auto_awesome, 
              color: offline ? Colors.grey : Colors.white, 
              size: 50.sp
            ), 
          ),
        ),
      ),
    );
  }

  Widget _buildDialogueBox(BuildContext context, HomeController controller) {
    // If we're fully idle/offline, maybe hide it? For now keep it visible as "System Status"
    
    bool isWorking = controller.agentState.value == 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: isWorking 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                   SizedBox(width: 16.w, height: 16.w, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor)),
                   SizedBox(width: 12.w),
                   Text("AGENT ACTIVE", style: TextStyle(color: AppTheme.accentColor, fontSize: 10.sp, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                 ],
               ),
               SizedBox(height: 12.h),
               Text(
                 controller.currentThought.value,
                 style: TextStyle(color: Colors.white, fontSize: 16.sp, fontFamily: 'Courier'), // Monospace for "Terminal" feel
               ),
            ],
          )
        : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.dialogueTitle.value,
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            controller.dialogueBody.value,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildReplyChip("Approve", () => controller.startDrafting()),
              SizedBox(width: 10.w),
              _buildReplyChip("Decline", () => controller.declineProposal()),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildReplyChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(color: AppTheme.primaryColor, fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInputChannels(BuildContext context) {
    // Inject Input Controller
    final inputController = Get.put(HomeInputController());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildChannelButton(Icons.camera_alt, "Vision", const Color(0xFF00E5FF), inputController.onCameraTap), // Cyan Neon
        _buildChannelButton(Icons.mic, "Voice", const Color(0xFFD500F9), inputController.onMicTap),       // Purple Neon
        _buildChannelButton(Icons.keyboard, "Text", const Color(0xFF2979FF), inputController.onKeyboardTap), // Blue Neon
      ],
    );
  }

  Widget _buildPanelContent(BuildContext context) {
    final inputController = Get.find<HomeInputController>();
    
    switch (inputController.activeChannel.value) {
      case InputChannel.camera:
        return _buildCameraPanel();
      case InputChannel.mic:
        return _buildMicPanel();
      case InputChannel.keyboard:
        return _buildKeyboardPanel(inputController);
      default:
        return SizedBox();
    }
  }

  Widget _buildCameraPanel() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Container(
            width: 60.w, height: 6.h,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
          ),
          SizedBox(height: 40.h),
          Icon(Icons.camera_alt, size: 60.sp, color: Color(0xFF00E5FF)),
          SizedBox(height: 20.h),
          Text("Visual Analysis", style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 10.h),
          Text("Take a photo or upload from gallery to analyze.", style: TextStyle(color: Colors.white54, fontSize: 16.sp), textAlign: TextAlign.center),
          SizedBox(height: 40.h),
          Row(
            children: [
              Expanded(child: _buildPanelButton(Icons.photo_library, "Gallery", Colors.white10)),
              SizedBox(width: 20.w),
              Expanded(child: _buildPanelButton(Icons.camera, "Camera", AppTheme.primaryColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMicPanel() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          Container(width: 60.w, height: 6.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
          Spacer(),
          Icon(Icons.mic, size: 80.sp, color: Color(0xFFD500F9)),
          SizedBox(height: 40.h),
          Text("Listening...", style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
          Spacer(),
        ],
      ),
    );
  }
  
  Widget _buildKeyboardPanel(HomeInputController controller) {
     return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 60.w, height: 6.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
          SizedBox(height: 20.h),
          Text("Agent Instruction", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 20.h),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.black26, 
                borderRadius: BorderRadius.circular(16.r)
              ),
              child: TextField(
                controller: controller.textInputController,
                maxLines: null,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type your request here...",
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
              onPressed: () => controller.closePanel(), // Mock send
              child: Text("Send to Agent", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPanelButton(IconData icon, String label, Color color) {
    return Container(
      height: 60.h,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          SizedBox(width: 10.w),
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChannelButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        width: 100.w,
        height: 110.h,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.2),
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5
              ),
            ),
          ],
        ),
      ),
    );
  }
}
