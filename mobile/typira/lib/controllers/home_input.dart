import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../packages/sliding_up_panel/sliding_up_panel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'home.dart';

enum InputChannel { none, camera, mic, keyboard, action_input, result }

class HomeInputController extends GetxController {
  
  final PanelController panelController = PanelController();
  var activeChannel = InputChannel.none.obs;

  // Voice Recording State
  final AudioRecorder audioRecorder = AudioRecorder();
  var isRecording = false.obs;
  var isPaused = false.obs;
  String? recordedPath;
  
  // Text Input State
  final textInputController = TextEditingController();

  void onCameraTap() {
    activeChannel.value = InputChannel.camera;
    panelController.open();
  }

  void onMicTap() {
    activeChannel.value = InputChannel.mic;
    panelController.open();
    startRecording();
  }

  void onKeyboardTap() {
    activeChannel.value = InputChannel.keyboard;
    panelController.open();
  }
  
  void closePanel() {
    if (isRecording.value || isPaused.value) {
      stopAndCancel();
    }
    panelController.close();
    
    // Clear analysis flags and resume priority loop
    final homeController = Get.find<HomeController>();
    homeController.clearAnalysisAndResume();

    // Delay resetting channel to avoid UI flicker during animation
    Future.delayed(const Duration(milliseconds: 300), () {
      activeChannel.value = InputChannel.none;
    });
  }

  Future<void> submitText() async {
    final text = textInputController.text.trim();
    if (text.isNotEmpty) {
      textInputController.clear();
      closePanel();
      final homeController = Get.find<HomeController>();
      homeController.processText(text);
    }
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        recordedPath = '${directory.path}/voice_cmd.m4a';
        
        const config = RecordConfig();
        await audioRecorder.start(config, path: recordedPath!);
        
        isRecording.value = true;
        isPaused.value = false;
        update();
      }
    } catch (e) {
      print("Start Recording Error: $e");
    }
  }

  Future<void> pauseRecording() async {
    await audioRecorder.pause();
    isPaused.value = true;
    update();
  }

  Future<void> resumeRecording() async {
    await audioRecorder.resume();
    isPaused.value = false;
    update();
  }

  Future<void> stopAndSend() async {
    final path = await audioRecorder.stop();
    isRecording.value = false;
    isPaused.value = false;
    
    if (path != null) {
      closePanel();
      final homeController = Get.find<HomeController>();
      homeController.processVoice(File(path));
    }
  }

  Future<void> stopAndCancel() async {
    await audioRecorder.stop();
    isRecording.value = false;
    isPaused.value = false;
    update();
  }

  @override
  void onClose() {
    audioRecorder.dispose();
    super.onClose();
  }

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70, // Optimize for Gemini
    );

    if (image != null) {
      closePanel();
      final homeController = Get.find<HomeController>();
      homeController.processImage(File(image.path));
    }
  }
}
