import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../api/memory_api.dart';

class MemoryItem {
  final String id;
  final String title;
  final String content;
  final String icon;
  final String timeAgo;
  final DateTime timestamp;

  MemoryItem({
    required this.id,
    required this.title,
    required this.content,
    required this.icon,
    required this.timeAgo,
    required this.timestamp,
  });

  factory MemoryItem.fromJson(Map<String, dynamic> json) {
    return MemoryItem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      icon: json['icon'] ?? '📝',
      timeAgo: json['time_ago'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}

class PaginatedData<T> {
  var items = <T>[].obs;
  var currentPage = 1.obs;
  var hasNext = true.obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;

  void reset() {
    items.clear();
    currentPage.value = 1;
    hasNext.value = true;
    isLoading.value = false;
    isLoadingMore.value = false;
  }
}

class MemoryController extends GetxController {
  final MemoryApi _api = MemoryApi();

  final memories = PaginatedData<MemoryItem>();
  final typingHistory = PaginatedData<MemoryItem>();
  final userActions = PaginatedData<MemoryItem>();

  @override
  void onInit() {
    super.onInit();
    fetchMemories();
    fetchTypingHistory();
    fetchUserActions();
  }

  Future<void> fetchMemories({bool isRefresh = false}) async {
    await _fetchData(memories, _api.getMemories, isRefresh: isRefresh);
  }

  Future<void> fetchTypingHistory({bool isRefresh = false}) async {
    await _fetchData(typingHistory, _api.getTypingHistory, isRefresh: isRefresh);
  }

  Future<void> fetchUserActions({bool isRefresh = false}) async {
    await _fetchData(userActions, _api.getUserActions, isRefresh: isRefresh);
  }

  Future<void> _fetchData(
    PaginatedData<MemoryItem> data,
    Future<dynamic> Function(int page) apiCall, {
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      data.reset();
    }

    if (data.isLoading.value || data.isLoadingMore.value || !data.hasNext.value) return;

    if (data.items.isEmpty) {
      data.isLoading.value = true;
    } else {
      data.isLoadingMore.value = true;
    }

    try {
      final response = await apiCall(data.currentPage.value);
      final List<dynamic> itemsJson = response['items'];
      final List<MemoryItem> newItems = itemsJson.map((j) => MemoryItem.fromJson(j)).toList();

      data.items.addAll(newItems);
      data.hasNext.value = response['has_next'] ?? false;
      if (data.hasNext.value) {
        data.currentPage.value++;
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load data: $e");
    } finally {
      data.isLoading.value = false;
      data.isLoadingMore.value = false;
    }
  }
}
