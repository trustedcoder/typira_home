import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../packages/sliding_up_panel/sliding_up_panel.dart';

enum InputChannel { none, camera, mic, keyboard, action_input, result }

class HomeInputController extends GetxController {
  
  final PanelController panelController = PanelController();
  var activeChannel = InputChannel.none.obs;
  
  // Text Input State
  final textInputController = TextEditingController();

  void onCameraTap() {
    activeChannel.value = InputChannel.camera;
    panelController.open();
  }

  void onMicTap() {
    activeChannel.value = InputChannel.mic;
    panelController.open();
  }

  void onKeyboardTap() {
    activeChannel.value = InputChannel.keyboard;
    panelController.open();
  }
  
  void closePanel() {
    panelController.close();
    // Delay resetting channel to avoid UI flicker during animation
    Future.delayed(const Duration(milliseconds: 300), () {
      activeChannel.value = InputChannel.none;
    });
  }
}
