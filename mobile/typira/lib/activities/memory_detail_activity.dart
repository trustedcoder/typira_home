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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          "Details",
          style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: controller.item.content));
              Get.snackbar(
                "Copied",
                "Content copied to clipboard",
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: const Color(0xFF1E293B),
                colorText: Colors.white,
              );
            },
          ),
          SizedBox(width: 8.w),
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
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                  ),
                  child: Text(
                    controller.item.icon,
                    style: TextStyle(fontSize: 28.sp),
                  ),
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
                        controller.item.timeAgo,
                        style: TextStyle(color: Colors.white54, fontSize: 13.sp, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              ],
            ),
            
            SizedBox(height: 32.h),
            Divider(color: Colors.white.withOpacity(0.05)),
            SizedBox(height: 32.h),

            // Content Body
            Container(
              padding: EdgeInsets.all(20.w),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: MarkdownBody(
                data: controller.item.content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(color: Colors.white, fontSize: 16.sp, height: 1.6),
                  h1: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
                  h2: TextStyle(color: const Color(0xFF6366F1), fontSize: 20.sp, fontWeight: FontWeight.bold),
                  strong: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  blockquote: TextStyle(
                    color: Colors.white70, 
                    fontStyle: FontStyle.italic,
                    decoration: TextDecoration.none,
                  ),
                  code: TextStyle(
                    color: const Color(0xFF6366F1), 
                    backgroundColor: Colors.black26, 
                    fontFamily: 'monospace'
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}
