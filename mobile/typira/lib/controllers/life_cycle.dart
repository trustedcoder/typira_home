import 'package:get/get.dart';

class LifeCycleController extends SuperController {

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