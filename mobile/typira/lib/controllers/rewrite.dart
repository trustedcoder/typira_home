import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class RewriteController extends GetxController {
  
  final textController = TextEditingController();
  var toneValue = 0.5.obs; // 0.0: Casual, 0.5: Neutral, 1.0: Formal
  var isThinking = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _checkClipboard();
  }
  
  void _checkClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      Get.snackbar(
        "Magic Paste", 
        "Found text in clipboard. Pasting it for you.",
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white,
        colorText: Colors.black,
        duration: const Duration(seconds: 2),
      );
      textController.text = data.text!;
    }
  }

  void performRewrite() async {
    if (textController.text.isEmpty) return;
    
    isThinking.value = true;
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    isThinking.value = false;
    
    String original = textController.text;
    String tone = getToneLabel(toneValue.value);
    
    // In a real app, this would be the AI response
    String result = "[$tone Version]: $original (Refined)"; 
    if (toneValue.value > 0.8) {
      result = "Pursuant to your request, kindly find the refined text: $original";
    } else if (toneValue.value < 0.2) {
      result = "Yo, check this out: $original";
    }
    
    textController.text = result;
  }
  
  String getToneLabel(double value) {
    if (value < 0.3) return "Casual";
    if (value > 0.7) return "Formal";
    return "Neutral";
  }
  
  Color getToneColor() {
    if (toneValue.value < 0.3) return const Color(0xFF27AF4D); // Green (Casual)
    if (toneValue.value > 0.7) return const Color(0xFF9C27B0); // Purple (Formal)
    return const Color(0xFFEEA525); // Orange (Neutral)
  }
}
