
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../controllers/setup_controller.dart';
import '../constants/app_theme.dart';
import 'dart:io';

class SetupActivity extends StatelessWidget {
  const SetupActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SetupController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(), // User must interact with buttons
                onPageChanged: controller.onPageChanged,
                children: [
                  _buildNotificationPage(controller),
                  _buildKeyboardPage(controller),
                ],
              ),
            ),
            
            // Indicators
            Padding(
               padding: EdgeInsets.only(bottom: 20.h),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: List.generate(
                   2,
                   (index) => Obx(() => AnimatedContainer(
                     duration: const Duration(milliseconds: 300),
                     margin: EdgeInsets.symmetric(horizontal: 4.w),
                     height: 6.h,
                     width: controller.currentPage.value == index ? 24.w : 6.w,
                     decoration: BoxDecoration(
                       color: controller.currentPage.value == index ? AppTheme.accentColor : Colors.white24,
                       borderRadius: BorderRadius.circular(3.r),
                     ),
                   )),
                 ),
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationPage(SetupController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Agent Notification Simulation
          Container(
             height: 200.h,
             width: double.infinity,
             alignment: Alignment.center,
             child: Stack(
               alignment: Alignment.center,
               children: [
                 // Background glow
                 Container(
                   width: 120.w, height: 120.w,
                   decoration: BoxDecoration(
                     shape: BoxShape.circle,
                     color: AppTheme.accentColor.withOpacity(0.2),
                     boxShadow: [
                       BoxShadow(color: AppTheme.accentColor.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)
                     ]
                   ),
                 ),
                 // Notification Card
                 Container(
                   width: 260.w,
                   padding: EdgeInsets.all(16.r),
                   decoration: BoxDecoration(
                     color: const Color(0xFF1E293B),
                     borderRadius: BorderRadius.circular(16.r),
                     border: Border.all(color: Colors.white12),
                     boxShadow: [
                       BoxShadow(color: Colors.black45, blurRadius: 20, offset: const Offset(0, 10))
                     ]
                   ),
                   child: Row(
                     children: [
                       Container(
                         padding: EdgeInsets.all(10.r),
                         decoration: BoxDecoration(color: AppTheme.whiteColor.withOpacity(0.5), shape: BoxShape.circle),
                         child: Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 24.sp),
                       ),
                       SizedBox(width: 16.w),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text("Agent Analysis", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp)),
                             SizedBox(height: 4.h),
                             Text("Found 3 new insights from your history", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                           ],
                         ),
                       )
                     ],
                   ),
                 ),
                 // Badge
                 Positioned(
                   top: 20.h, right: 10.w,
                   child: Container(
                     padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                     decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10.r)),
                     child: Text("1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10.sp)),
                   ),
                 )
               ],
             ),
          ),
          SizedBox(height: 40.h),
          Text(
            "Track Agent Activity",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            "Get instant alerts when your AI Agent completes background tasks, generates insights, or finishes work for you.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 60.h),
          InkWell(
            onTap: () => controller.requestNotificationPermission(),
            borderRadius: BorderRadius.circular(30.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Text(
                "Enable Notifications",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardPage(SetupController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (Platform.isIOS)
            const IosSetupAnimationWidget() 
          else if (Platform.isAndroid)
            const AndroidSetupAnimationWidget()
          else 
            Container(
               height: 250.h,
               child: Icon(Icons.keyboard_alt_outlined, size: 100.sp, color: AppTheme.accentColor),
            ),
          SizedBox(height: 24.h), // Reduced spacing
          Text(
            "Enable Typira Keyboard",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            Platform.isIOS 
              ? "Follow the steps above to enable full access."
              : "Enable Typira Keyboard in your settings to start using AI features.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
              height: 1.5,
            ),
          ),
          // Privacy Warning
          ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.withOpacity(0.3))
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "We don't store sensitive information like credit cards or passwords.",
                      style: TextStyle(color: Colors.orange[200], fontSize: 12.sp, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 30.h),
          InkWell(
            onTap: () => controller.openKeyboardSettings(),
            borderRadius: BorderRadius.circular(30.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Text(
                "Open Settings",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          InkWell(
            onTap: () => controller.finishSetup(),
            borderRadius: BorderRadius.circular(30.r),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                ]
              ),
              child: Text(
                "I've Done it",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AndroidSetupAnimationWidget extends StatefulWidget {
  const AndroidSetupAnimationWidget({super.key});

  @override
  State<AndroidSetupAnimationWidget> createState() => _AndroidSetupAnimationWidgetState();
}

class _AndroidSetupAnimationWidgetState extends State<AndroidSetupAnimationWidget> {
  int _currentStep = 0;
  late final List<Widget> _steps;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _steps = [
      Image.asset('assets/images/android_step_1.png', fit: BoxFit.contain), // Manage Keyboards list
      Image.asset('assets/images/android_step_2.png', fit: BoxFit.contain), // Attention dialog
      Image.asset('assets/images/android_step_3.png', fit: BoxFit.contain), // Enabled toggle
    ];

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, // Android screenshots usually have white background
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white24, width: 2)
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
               duration: const Duration(milliseconds: 500),
               child: KeyedSubtree(
                 key: ValueKey<int>(_currentStep),
                 child: SizedBox.expand(
                   child: _steps[_currentStep]
                 ),
               ),
            ),
          ),
          
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: 8.w, height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentStep ? AppTheme.accentColor : Colors.black26
                ),
              )),
            ),
          )
        ],
      ),
    );
  }
}

class IosSetupAnimationWidget extends StatefulWidget {
  const IosSetupAnimationWidget({super.key});

  @override
  State<IosSetupAnimationWidget> createState() => _IosSetupAnimationWidgetState();
}

class _IosSetupAnimationWidgetState extends State<IosSetupAnimationWidget> {
  int _currentStep = 0;
  late final List<Widget> _steps;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _steps = [
      Image.asset('assets/images/ios_step_1.png', fit: BoxFit.contain), // Settings > Typira
      Image.asset('assets/images/ios_step_2.png', fit: BoxFit.contain), // Typira Menu
      Image.asset('assets/images/ios_step_3.png', fit: BoxFit.contain), // Alert
      Image.asset('assets/images/ios_step_4.png', fit: BoxFit.contain), // Full Access ON
    ];

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _steps.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220.h, // Adjusted height for screenshots
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black, 
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white24, width: 2)
      ),
      clipBehavior: Clip.antiAlias, // Clip image corners
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
               duration: const Duration(milliseconds: 500),
               child: KeyedSubtree(
                 key: ValueKey<int>(_currentStep),
                 child: SizedBox.expand(
                   child: _steps[_currentStep]
                 ),
               ),
            ),
          ),
          
          // Step Indicator overlay
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4.w),
                width: 8.w, height: 8.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentStep ? AppTheme.accentColor : Colors.white54
                ),
              )),
            ),
          )
        ],
      ),
    );
  }
}
