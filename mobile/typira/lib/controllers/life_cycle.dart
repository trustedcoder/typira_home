import 'package:get/get.dart';
import '../services/notification.dart';

class LifeCycleController extends SuperController {

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onDetached() {

  }

  @override
  void onInactive() {
  }

  @override
  void onPaused() {
  }

  @override
  void onResumed() {

    /// on app coming to foreground always check if token is expired
  }

  @override
  void onHidden() {
    // TODO: implement onHidden
  }

}