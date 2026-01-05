import 'package:get/get.dart';

class RouteConfig {
  static navigateToPage(String page) {
    Get.toNamed(page);
  }
  static navigateToReplacePage(String page) {
    Get.offAllNamed(page);
  }
  static navigateToReplacePageWithData(String page, Map<String, dynamic> data) {
    Get.offAllNamed(page, arguments: data);
  }
  static navigateToPageWithData(String page, Map<String, dynamic> data) {
    Get.toNamed(page, arguments: data);
  }

}