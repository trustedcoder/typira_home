import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get.dart';
import '../controllers/memory_controller.dart';
import '../activities/memory_detail_activity.dart';
import '../constants/app_theme.dart';

class MemoryFragment extends StatelessWidget {
  const MemoryFragment({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MemoryController());

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Text(
              "Agent Memory",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Obx(() => GridView.builder(
              padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 0, bottom: 100.h), // Added bottom padding
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.w,
                mainAxisSpacing: 16.h,
                childAspectRatio: 0.85,
              ),
              itemCount: controller.memoryItems.length,
              itemBuilder: (context, index) {
                final item = controller.memoryItems[index];
                return _buildMemoryCard(item);
              },
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(MemoryItem item) {
    return InkWell(
      onTap: () => Get.to(() => const MemoryDetailActivity(), arguments: item),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                   color: item.color.withOpacity(0.1),
                   shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 20.sp),
              ),
              Text(
                item.timestamp,
                style: TextStyle(color: Colors.white38, fontSize: 10.sp),
              ),
            ],
          ),
          Spacer(),
          Text(
            item.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Text(
            item.contentSnippet,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ));
  }
}
