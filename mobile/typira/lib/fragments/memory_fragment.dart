import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/memory_controller.dart';
import '../activities/memory_detail_activity.dart';
import '../constants/app_theme.dart';

class MemoryFragment extends StatefulWidget {
  const MemoryFragment({super.key});

  @override
  State<MemoryFragment> createState() => _MemoryFragmentState();
}

class _MemoryFragmentState extends State<MemoryFragment> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(MemoryController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF6366F1),
            labelColor: const Color(0xFF6366F1),
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: "Memory"),
              Tab(text: "Typing"),
              Tab(text: "Actions"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaginatedList(controller.memories, controller.fetchMemories),
                _buildPaginatedList(controller.typingHistory, controller.fetchTypingHistory),
                _buildPaginatedList(controller.userActions, controller.fetchUserActions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginatedList(PaginatedData<MemoryItem> data, Future<void> Function({bool isRefresh}) fetchFn) {
    return RefreshIndicator(
      onRefresh: () => fetchFn(isRefresh: true),
      child: Obx(() {
        if (data.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
        }

        if (data.items.isEmpty) {
          return Center(
            child: Text(
              "No items found",
              style: TextStyle(color: Colors.white38, fontSize: 16.sp),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(left: 20.w, right: 20.w, top: 16.h, bottom: 100.h),
          itemCount: data.items.length + (data.hasNext.value ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == data.items.length) {
              // Load more trigger
              if (!data.isLoadingMore.value) {
                Future.microtask(() => fetchFn());
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              );
            }

            final item = data.items[index];
            return _buildMemoryItemTile(item);
          },
        );
      }),
    );
  }

  Widget _buildMemoryItemTile(MemoryItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16.w),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            item.icon,
            style: TextStyle(fontSize: 20.sp),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              item.timeAgo,
              style: TextStyle(color: Colors.white38, fontSize: 11.sp),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8.h),
          child: Text(
            item.content,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13.sp,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onTap: () => Get.to(() => const MemoryDetailActivity(), arguments: item),
      ),
    );
  }
}
