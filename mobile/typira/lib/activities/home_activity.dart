import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_theme.dart';
import '../controllers/home.dart';
import '../controllers/home_input.dart';
import '../packages/sliding_up_panel/sliding_up_panel.dart';
import '../fragments/memory_fragment.dart';
import '../fragments/insights_fragment.dart';
import 'rewrite_activity.dart'; // Import Rewrite Activity

class HomeActivity extends StatelessWidget {
  HomeActivity({super.key});

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
        onPanelClosed: () => Get.find<HomeInputController>().closePanel(),
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
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Obx(() => _buildHeader(context, controller)),
            SizedBox(height: 5.h),
            Obx(() => _buildAgentCore(context, controller)),
            SizedBox(height: 45.h),
            // Make dialogue box take the remaining space
            Expanded(child: Obx(() => _buildDialogueBox(context, controller))),
            SizedBox(height: 10.h),
            Expanded(child: _buildInputChannels(context)),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, HomeController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${_getTimeBasedGreeting()}, ${controller.userName.value}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter', // Assuming standard font
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8.w, height: 8.w,
                  decoration: BoxDecoration(
                    color: controller.isOffline.value ? Colors.red : AppTheme.greenColor,
                    shape: BoxShape.circle
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  controller.isOffline.value ? "System Offline" : "System Online • Ready",
                  style: TextStyle(
                    color: controller.isOffline.value ? Colors.red : AppTheme.greenColor,
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
            Get.toNamed("/settings");
          },
          icon: const Icon(Icons.settings, color: Colors.white54)
        )
      ],
    );
  }

  String _getTimeBasedGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Widget _buildAgentCore(BuildContext context, HomeController controller) {
    bool offline = controller.isOffline.value;
    bool thinking = controller.isThinking.value;

    return Center(
      child: Container(
        width: 150.w,
        height: 150.w,
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
            width: 100.w,
            height: 100.w,
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
    
    bool isWorking = controller.agentState.value == 2;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 120.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unified Header
          Row(
            children: [
              if (isWorking)
                SizedBox(width: 14.w, height: 14.w, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor))
              else
                Icon(Icons.auto_awesome, color: AppTheme.greenColor, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                (isWorking ? "AGENT THINKING" : controller.dialogueTitle.value).toUpperCase(),
                style: TextStyle(
                  color: isWorking ? AppTheme.accentColor : AppTheme.greenColor,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          if (controller.thoughts.isNotEmpty) ...[
            GestureDetector(
              onTap: () => controller.isThoughtsExpanded.toggle(),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Text(
                    "Thought process",
                    style: TextStyle(color: Colors.white54, fontSize: 10.sp, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    controller.isThoughtsExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white54,
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 5.h),
          // Content Area
          if (controller.isThoughtsExpanded.value && controller.thoughts.isNotEmpty) ...[
            Expanded(
              child: _buildThoughtsList(controller),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  isWorking ? controller.currentThought.value : controller.dialogueBody.value,
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16.sp, 
                    fontFamily: isWorking ? 'Courier' : 'Inter',
                    fontWeight: isWorking ? FontWeight.normal : FontWeight.w400
                  ),
                ),
              ),
            ),
          ],
          // Actions Area (Chip row)
          if (!isWorking && controller.agentState.value == 1 && controller.dynamicActions.isNotEmpty) ...[
            SizedBox(height: 12.h),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.dynamicActions.map((action) {
                  final index = controller.dynamicActions.indexOf(action);
                  return Padding(
                    padding: EdgeInsets.only(right: 12.w),
                    child: _buildReplyChip(
                      action['label'] ?? "Select", 
                      () => controller.handleDynamicAction(action),
                      isPrimary: index == 0 && action['id'] != "none" && action['id'] != "decline",
                    ),
                  );
                }).toList(),
              ),
            )
          ]
        ],
      ),
    );

  }

  final ScrollController _thoughtsScrollController = ScrollController();

  Widget _buildThoughtsList(HomeController controller) {
    // Auto-scroll logic
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_thoughtsScrollController.hasClients) {
        _thoughtsScrollController.animateTo(
          _thoughtsScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListView.builder(
        controller: _thoughtsScrollController,
        itemCount: controller.thoughts.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "> ",
                  style: TextStyle(color: AppTheme.accentColor, fontSize: 13.sp, fontFamily: 'Courier'),
                ),
                Expanded(
                  child: Text(
                    controller.thoughts[index],
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13.sp, fontFamily: 'Courier'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyChip(String label, VoidCallback onTap, {bool isPrimary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isPrimary ? AppTheme.primaryColor : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.black : Colors.white, 
            fontSize: 13.sp, 
            fontWeight: FontWeight.bold
          ),
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
      case InputChannel.action_input:
        return _buildActionInputPanel(inputController);
      case InputChannel.result:
        return _buildResultPanel();
      default:
        return SizedBox();
    }
  }

  Widget _buildCameraPanel() {
    final inputController = Get.find<HomeInputController>();
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
              Expanded(child: _buildPanelButton(Icons.photo_library, "Gallery", Colors.white10, () => inputController.pickImage(ImageSource.gallery))),
              SizedBox(width: 20.w),
              Expanded(child: _buildPanelButton(Icons.camera, "Camera", AppTheme.primaryColor, () => inputController.pickImage(ImageSource.camera))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMicPanel() {
    final inputController = Get.find<HomeInputController>();
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Obx(() {
        final isRecording = inputController.isRecording.value;
        final isPaused = inputController.isPaused.value;

        return Column(
          children: [
            Container(width: 60.w, height: 6.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            SizedBox(height: 40.h),
            
            // Pulse Animation / Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: isRecording && !isPaused ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutBack,
              onEnd: () {
                // This doesn't infinite loop easily in TweenAnimationBuilder without extra logic,
                // but for a simple indicator it works well enough or we can use a more static approach.
              },
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isRecording && !isPaused ? Color(0xFFD500F9).withOpacity(0.2) : Colors.transparent,
                    ),
                    child: Icon(
                      isPaused ? Icons.pause_circle : Icons.mic,
                      size: 80.sp,
                      color: Color(0xFFD500F9),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 30.h),
            Text(
              isPaused ? "Recording Paused" : "Listening...",
              style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Text(
              "Speak clearly for the best analysis.",
              style: TextStyle(color: Colors.white54, fontSize: 16.sp),
            ),
            
            Spacer(),

            Row(
              children: [
                Expanded(
                  child: _buildPanelButton(
                    isPaused ? Icons.play_arrow : Icons.pause,
                    isPaused ? "Resume" : "Pause",
                    Colors.white10,
                    () => isPaused ? inputController.resumeRecording() : inputController.pauseRecording(),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: _buildPanelButton(
                    Icons.send,
                    "Send",
                    AppTheme.primaryColor,
                    () => inputController.stopAndSend(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            TextButton(
              onPressed: () => inputController.closePanel(),
              child: Text("Cancel", style: TextStyle(color: Colors.white54, fontSize: 16.sp)),
            ),
          ],
        );
      }),
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
          Text(
            "Agent Instruction", 
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)
          ),
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
              onPressed: () => controller.submitText(),
              child: Text("Send to Agent", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionInputPanel(HomeInputController inputController) {
    final homeController = Get.find<HomeController>();
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 60.w, height: 6.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
          SizedBox(height: 20.h),
          Text(
            "Tell Typira more", 
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.black26, 
                borderRadius: BorderRadius.circular(16.r)
              ),
              child: TextField(
                controller: inputController.textInputController,
                maxLines: null,
                autofocus: true,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type your response...",
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () {
                final text = inputController.textInputController.text;
                if (text.isNotEmpty) {
                  homeController.submitActionInput(text);
                }
              },
              child: Text("Submit", style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    final homeController = Get.find<HomeController>();
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 60.w, height: 6.h, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
          SizedBox(height: 20.h),
          Text(
            "Agent Result", 
            style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.black26, 
                borderRadius: BorderRadius.circular(16.r)
              ),
              child: SingleChildScrollView(
                child: Text(
                  homeController.lastResult.value,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, height: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          
          if (homeController.resultThoughts.isNotEmpty) ...[
             Obx(() => Column(
               children: [
                 InkWell(
                   onTap: () => homeController.isResultThoughtsExpanded.toggle(),
                   child: Row(
                     children: [
                       Text("Thought Process", style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
                       SizedBox(width: 4.w),
                       Icon(
                          homeController.isResultThoughtsExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white54,
                          size: 20.sp,
                        ),
                     ],
                   ),
                 ),
                 if (homeController.isResultThoughtsExpanded.value)
                   Container(
                     height: 150.h,
                     margin: EdgeInsets.only(top: 8.h),
                     padding: EdgeInsets.all(8.w),
                     decoration: BoxDecoration(
                        color: Colors.black26, 
                        borderRadius: BorderRadius.circular(12.r)
                      ),
                      child: ListView.builder(
                        itemCount: homeController.resultThoughts.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("> ", style: TextStyle(color: AppTheme.accentColor, fontSize: 12.sp, fontFamily: 'Courier')),
                                Expanded(child: Text(homeController.resultThoughts[index], style: TextStyle(color: Colors.white70, fontSize: 12.sp, fontFamily: 'Courier'))),
                              ],
                            ),
                          );
                        },
                      ),
                   )
               ],
             )),
             SizedBox(height: 20.h),
          ],

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.copy,
                  label: "Copy",
                  color: Colors.white10,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: homeController.lastResult.value));
                    Get.snackbar(
                      "Copied",
                      "Result copied to clipboard",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppTheme.accentColor,
                      colorText: Colors.white,
                    );
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share,
                  label: "Share",
                  color: Colors.white10,
                  onTap: () {
                    Share.share(homeController.lastResult.value);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              onPressed: () => Get.find<HomeInputController>().closePanel(),
              child: Text("Done", style: TextStyle(color: Colors.black, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
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
      ),
    );
  }

  Widget _buildChannelButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        width: 100.w,
        height: 180.h,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
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
