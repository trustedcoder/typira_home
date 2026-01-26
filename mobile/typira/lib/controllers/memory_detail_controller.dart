import 'package:get/get.dart';
import '../api/memory_api.dart';
import 'memory_controller.dart';

class MemoryDetailController extends GetxController {
  final MemoryApi _api = MemoryApi();
  final item = Rxn<MemoryItem>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    if (Get.arguments != null) {
      if (Get.arguments is MemoryItem) {
        item.value = Get.arguments as MemoryItem;
      } else if (Get.arguments is String) {
        fetchDetail(Get.arguments as String);
      }
    } else {
      Get.back();
       Get.snackbar(
        "Error", 
        "Memory item not found",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> fetchDetail(String id) async {
    isLoading.value = true;
    try {
      final response = await _api.getMemoryDetail(id);
      item.value = MemoryItem.fromJson(response);
    } catch (e) {
      Get.snackbar("Error", "Failed to load details: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
