import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_theme.dart';
import '../controllers/rewrite.dart';

class RewriteActivity extends StatelessWidget {
  const RewriteActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(RewriteController());
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Rewrite Studio", style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
        leading: IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back, color: Colors.white)),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Input Area
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: controller.textController,
                  maxLines: null,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type or paste text to rewrite...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 16.sp),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 24.h),
            
            // Tone Slider
            Obx(() => Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text("Casual", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                       Text(
                         controller.getToneLabel(controller.toneValue.value).toUpperCase(), 
                         style: TextStyle(
                           color: controller.getToneColor(), 
                           fontWeight: FontWeight.bold, 
                           fontSize: 12.sp
                         )
                       ),
                       Text("Formal", style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                     ],
                   ),
                   SliderTheme(
                     data: SliderTheme.of(context).copyWith(
                       activeTrackColor: controller.getToneColor(),
                       inactiveTrackColor: Colors.white10,
                       thumbColor: Colors.white,
                       overlayColor: controller.getToneColor().withOpacity(0.2),
                     ),
                     child: Slider(
                       value: controller.toneValue.value, 
                       onChanged: (val) => controller.toneValue.value = val,
                     ),
                   )
                ],
              ),
            )),
            
            SizedBox(height: 24.h),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: Obx(() => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                onPressed: controller.isThinking.value ? null : () => controller.performRewrite(),
                child: controller.isThinking.value 
                  ? SizedBox(width: 24.w, height: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Refine Text", style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              )),
            )
          ],
        ),
      ),
    );
  }
}
