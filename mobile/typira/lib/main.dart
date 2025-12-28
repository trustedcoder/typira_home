import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart' as dio;

void main() async {
  await GetStorage.init();
  runApp(const TypiraIntelligenceApp());
}

class TypiraController extends GetxController {
  static const platform = MethodChannel('com.typira.typira/intelligence');
  var status = "Ready".obs;
  var memories = <String>[].obs;
  final storage = GetStorage();
  final _dio = dio.Dio(dio.BaseOptions(baseUrl: 'http://10.0.2.2:8000')); // Android Emulator IP

  @override
  void onInit() {
    super.onInit();
    List<dynamic>? stored = storage.read<List<dynamic>>('memories');
    if (stored != null) {
      memories.assignAll(stored.cast<String>());
    }
    
    platform.setMethodCallHandler(_handleMethod);
  }

  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "processVoiceFile":
        final String path = call.arguments;
        return _uploadVoice(path);
      case "rememberText":
        final String text = call.arguments;
        _saveMemory(text);
        return true;
      case "requestRewrite":
        final String text = call.arguments;
        return _requestRewrite(text);
      default:
        throw PlatformException(code: "Unimplemented", message: "Method ${call.method} not implemented");
    }
  }

  void _saveMemory(String text) {
    if (!memories.contains(text)) {
      memories.add(text);
      storage.write('memories', memories.toList());
      status.value = "🧠 New Memory Saved";
    }
  }

  Future<void> _requestRewrite(String text) async {
    try {
      status.value = "Rewriting with context...";
      final contextString = memories.join(". ");
      
      final response = await _dio.post('/rewrite', data: dio.FormData.fromMap({
        'text': text,
        'context': contextString,
        'tone': 'professional', // Could be dynamic
      }));

      if (response.statusCode == 200) {
        final rewrittenText = response.data['rewritten_text'] as String;
        status.value = "Rewrite Complete";
        await platform.invokeMethod('commitText', rewrittenText);
      } else {
        status.value = "Rewrite Failed";
      }
    } catch (e) {
      status.value = "AI Offline";
      print("Rewrite error: $e");
    }
  }

  Future<void> _uploadVoice(String path) async {
    try {
      status.value = "Transcribing...";
      final formData = dio.FormData.fromMap({
        'audio_file': await dio.MultipartFile.fromFile(path, filename: 'voice.m4a'),
      });

      final response = await _dio.post('/stt', data: formData);
      if (response.statusCode == 200) {
        final transcript = response.data['transcript'] as String;
        status.value = "Voice Inserted";
        // Commit text back to keyboard
        await platform.invokeMethod('commitText', transcript);
      } else {
        status.value = "Error: ${response.statusMessage}";
      }
    } catch (e) {
      status.value = "Upload Failed";
      print("Upload error: $e");
    }
  }
}

class TypiraIntelligenceApp extends StatelessWidget {
  const TypiraIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Typira Intelligence',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});
  final controller = Get.put(TypiraController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧠 Typira Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              controller.memories.clear();
              controller.storage.remove('memories');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Obx(() => Card(
              color: Colors.blue.shade50,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('Status: ${controller.status.value}'),
              ),
            )),
            const SizedBox(height: 20),
            const Text('User Memories (Context)', style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: controller.memories.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.memory, size: 20),
                      title: Text(controller.memories[index]),
                    ),
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}
