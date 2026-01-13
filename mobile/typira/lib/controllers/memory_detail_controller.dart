import 'package:get/get.dart';
import 'memory_controller.dart';

class MemoryDetailController extends GetxController {
  late MemoryItem item;

  @override
  void onInit() {
    super.onInit();
    // Retrieve the item passed via arguments
    if (Get.arguments != null && Get.arguments is MemoryItem) {
      item = Get.arguments as MemoryItem;
    } else {
      // Fallback or error handling
      Get.back(); 
      Get.snackbar("Error", "Memory item not found");
    }
  }
}
