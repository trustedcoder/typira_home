import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../controllers/intro_controller.dart';
import '../constants/app_theme.dart';

class IntroActivity extends StatelessWidget {
  const IntroActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(IntroController());
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => controller.finishIntro(),
                child: Text("SKIP", style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
              ),
            ),
            
            Expanded(
              child: PageView.builder(
                controller: controller.pageController,
                onPageChanged: controller.onPageChanged,
                itemCount: controller.contents.length,
                itemBuilder: (context, index) {
                  return _buildPage(controller.contents[index]);
                },
              ),
            ),

            // Bottom Controls
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Indicators
                   Row(
                     children: List.generate(
                       controller.contents.length,
                       (index) => Obx(() => AnimatedContainer(
                         duration: const Duration(milliseconds: 300),
                         margin: EdgeInsets.only(right: 6.w),
                         height: 6.h,
                         width: controller.currentPage.value == index ? 24.w : 6.w,
                         decoration: BoxDecoration(
                           color: controller.currentPage.value == index ? AppTheme.accentColor : Colors.white24,
                           borderRadius: BorderRadius.circular(3.r),
                         ),
                       )),
                     ),
                   ),

                   // Next/Done Button
                   Obx(() {
                     bool isLast = controller.currentPage.value == controller.contents.length - 1;
                     return InkWell(
                       onTap: () => controller.next(),
                       borderRadius: BorderRadius.circular(30.r),
                       child: Container(
                         padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                         decoration: BoxDecoration(
                           color: AppTheme.primaryColor,
                           borderRadius: BorderRadius.circular(30.r),
                           boxShadow: [
                             BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                           ]
                         ),
                         child: Row(
                           children: [
                             Text(
                               isLast ? "Get Started" : "Next",
                               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                             ),
                             if (!isLast) ...[
                               SizedBox(width: 8.w),
                               Icon(Icons.arrow_forward, color: Colors.white, size: 20.sp),
                             ]
                           ],
                         ),
                       ),
                     );
                   })
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(IntroContent content) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           // Lottie Animation
           Container(
             height: 300.h,
             width: double.infinity,
             child: Lottie.asset(
               content.lottieAsset,
               fit: BoxFit.contain,
               errorBuilder: (context, error, stackTrace) {
                 // Fallback if asset is missing (Visual Placeholder)
                 return Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.movie_creation_outlined, size: 80.sp, color: Colors.white24),
                     SizedBox(height: 16.h),
                     Text("Place '${content.lottieAsset.split('/').last}' here", style: TextStyle(color: Colors.white24, fontSize: 12.sp)),
                   ],
                 );
               },
             ),
           ),
           SizedBox(height: 40.h),
           Text(
             content.title,
             textAlign: TextAlign.center,
             style: TextStyle(
               color: Colors.white,
               fontSize: 28.sp,
               fontWeight: FontWeight.bold,
               fontFamily: 'Inter',
               height: 1.2
             ),
           ),
           SizedBox(height: 16.h),
           Text(
             content.description,
             textAlign: TextAlign.center,
             style: TextStyle(
               color: Colors.white70,
               fontSize: 16.sp,
               height: 1.5,
             ),
           ),
        ],
      ),
    );
  }
}
