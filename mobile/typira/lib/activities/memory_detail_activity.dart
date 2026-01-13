import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/memory_detail_controller.dart';
import '../constants/app_theme.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class MemoryDetailActivity extends StatelessWidget {
  const MemoryDetailActivity({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject Controller
    final controller = Get.put(MemoryDetailController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {}, // Mock share
          ),
          SizedBox(width: 16.w),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: controller.item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: controller.item.color.withOpacity(0.3)),
                  ),
                  child: Icon(controller.item.icon, color: controller.item.color, size: 28.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.item.title,
                        style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "${controller.item.timestamp} • ${controller.item.type.toUpperCase()}",
                        style: TextStyle(color: Colors.white54, fontSize: 12.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              ],
            ),
            
            SizedBox(height: 32.h),
            Divider(color: Colors.white10),
            SizedBox(height: 32.h),

            // Content Body based on Type
            _buildContentBody(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody(MemoryDetailController controller) {
    // If it's an image type and no path mock, we show placeholder
    if (controller.item.type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 250.h,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(child: Icon(Icons.image, size: 60.sp, color: Colors.white24)),
          ),
          SizedBox(height: 24.h),
          Text(
            controller.item.fullContent,
            style: TextStyle(color: Colors.white70, fontSize: 16.sp, height: 1.5),
          ),
        ],
      );
    }

    // Default Text / Markdown view
    // Using simple Text for now if markdown package missing, but formatted styles
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: MarkdownBody(
        data: controller.item.fullContent,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(color: Colors.white, fontSize: 16.sp, height: 1.6),
          h1: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
          h2: TextStyle(color: AppTheme.accentColor, fontSize: 20.sp, fontWeight: FontWeight.bold),
          strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          blockquote: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
          code: TextStyle(color: AppTheme.accentColor, backgroundColor: Colors.black26, fontFamily: 'monospace'),
          listBullet: TextStyle(color: AppTheme.accentColor),
        ),
      ),
    );
  }
}
