import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:typira/storage/session_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_settings/app_settings.dart';
import 'dart:async';
import '../services/socket_service.dart';
import '../api/user_api.dart';
import '../controllers/home_input.dart';
import '../services/calendar_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:mime/mime.dart';

class HomeController extends GetxController {
  
  final socketService = SocketService();
  final userApi = UserApi();
  final calendarService = CalendarService();

  // Agent State
  var isOffline = true.obs;
  var isThinking = false.obs;
  
  // Navigation State
  var tabIndex = 0.obs;

  // Profile State
  var userName = "User".obs;

  // Agent Dialogue State
  // 0: Idle/Searching 
  // 1: Task Proposing (Approve/Decline)
  // 2: Working (Internal Monologue)
  // 3: Showing Result
  var agentState = 0.obs; 
  
  // Dynamic Content
  var dialogueTitle = "Initializing...".obs;
  var dialogueBody = "Connecting to Agent Core...".obs;
  var currentThought = "".obs;
  var currentActionId = "".obs;
  var dynamicActions = <Map<String, dynamic>>[].obs;
  var lastResult = "".obs;
  
  // Retry Context
  String _lastActionId = "";
  dynamic _lastActionPayload = "";
  String? _lastUserInput;
  bool _isImageAnalysisActive = false;
  bool _isVoiceAnalysisActive = false;
  bool _isTextAnalysisActive = false;
  Timer? _priorityTimer;

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
    setupSocket();
  }

  void fetchProfile() async {
    userName.value = SessionManager.getUserName();
    update();
    try {
      final resp = await userApi.getUserProfile();
      if (resp['status'] == 1) {
        userName.value = resp['data']['name'];
        SessionManager.setUserName(userName.value);
      }
    } catch (e) {
      print("Profile Error: $e");
    }
  }

  void setupSocket() {
    socketService.onConnectionStatus = (isConnected) {
      isOffline.value = !isConnected;
      if (isConnected) {
        agentState.value = 0; // Searching/Idle
        dialogueTitle.value = "Typira Online";
        dialogueBody.value = "Hello! I'm ready to assist you.";
        currentThought.value = "Checking in...";
        // Request initial priority task once ready

        socketService.getPriority();
        
        _priorityTimer?.cancel();
        _priorityTimer = Timer(const Duration(seconds: 3), () {
          if (!isClosed && !_isImageAnalysisActive && !_isVoiceAnalysisActive && !_isTextAnalysisActive) {
            agentState.value = 2; // Working
            isThinking.value = true;
            dialogueTitle.value = "Working...";
            dialogueBody.value = "Am going through your data.";
            currentThought.value = "Am going through your data...";
            update();
          }
        });
      } else {
        dialogueTitle.value = "System Offline";
        dialogueBody.value = "Check your connection.";
        dynamicActions.clear(); // Clear chips on offline
      }
      update();
    };

    socketService.onPriorityTask = (task) {
      _priorityTimer?.cancel();
      agentState.value = 1; // Proposing
      isThinking.value = false;
      dialogueTitle.value = task['title'] ?? "Priority Detected";
      dialogueBody.value = task['thought'] ?? "";
      
      final actions = task['actions'] as List? ?? [];
      dynamicActions.assignAll(actions.map((e) => Map<String, dynamic>.from(e)).toList());
      
      // For legacy/simple handling if needed, but we use dynamicActions now
      if (dynamicActions.isNotEmpty) {
        currentActionId.value = dynamicActions[0]['id'] ?? "none";
        _lastTaskPayload = dynamicActions[0]['payload'] ?? "";
      }
    };

    socketService.onThoughtUpdate = (thought) {
      _priorityTimer?.cancel();
      agentState.value = 2; // Working
      isThinking.value = true;
      currentThought.value = thought;
    };

    socketService.onActionResult = (data) {
      isThinking.value = false;
      final result = data['result'] ?? "";
      
      if (result.toString().trim().isEmpty || result == "Error executing action.") {
        // Handle failure: skip result panel and show retry dialogue
        agentState.value = 1; // Show as "Intervention Required"
        dialogueTitle.value = "Execution Failed";
        dialogueBody.value = "I encountered an error while performing that task. Would you like me to try again?";
        
        dynamicActions.assignAll([
          {
            "id": _lastActionId,
            "label": "🔄 Retry",
            "type": "retry",
            "payload": _lastActionPayload
          },
          {
            "id": "none",
            "label": "❌ Cancel",
            "type": "none",
            "payload": ""
          }
        ]);
      } else {
        // Success: normal flow
        agentState.value = 0; // Back to Idle
        lastResult.value = result;
        showResultPanel(data['action_id'], result);

        // Wait 5 seconds for user to read result, then fetch next task
        _priorityTimer?.cancel();
        _priorityTimer = Timer(const Duration(seconds: 5), () {
          if (!isClosed && !_isImageAnalysisActive && !_isVoiceAnalysisActive && !_isTextAnalysisActive) {
            agentState.value = 2; // Working
            isThinking.value = true;
            dialogueTitle.value = "Working...";
            dialogueBody.value = "Preparing next task.";
            currentThought.value = "Getting ready for the next task...";
            update();
            socketService.getPriority();
          }
        });
      }
    };

    socketService.connect();
  }

  dynamic _lastTaskPayload = "";

  void handleDynamicAction(Map<String, dynamic> action) {
    final actionId = action['id'] ?? "none";
    final payload = action['payload'] ?? "";
    final type = action['type'] ?? "prompt_trigger";

    if (type == "none" || actionId == "none" || actionId == "decline") {
      // Use the primary action's ID and payload as context for why we are declining
      final targetActionId = dynamicActions.isNotEmpty ? dynamicActions[0]['id'] : actionId;
      final contextPayload = dynamicActions.isNotEmpty ? dynamicActions[0]['payload'] : payload;
      declineTaskWithId(targetActionId, payload: contextPayload);
      return;
    }

    if (type == "deep_link") {
      openDeepLink(payload);
      // Still record as handled so it doesn't pop up again
      executeAction(actionId, payload, isSilent: true); 
      return;
    }

    if (type == "calendar_event") {
      createCalendarEvent(actionId, payload);
      return;
    }

    if (type == "input") {
      // Open input panel
      final inputController = Get.find<HomeInputController>();
      inputController.activeChannel.value = InputChannel.action_input;
      
      // Store current action details for submission
      _pendingActionId = actionId;
      _pendingPayload = payload;
      
      inputController.textInputController.clear();
      inputController.panelController.open();
    } else if (type == "retry") {
      executeAction(actionId, payload, userInput: _lastUserInput);
    } else {
      executeAction(actionId, payload);
    }
  }

  Future<void> openDeepLink(String url) async {
    final uri = Uri.parse(url);
    try {
      // Attempt launch directly. If the app isn't installed, it should throw or fail.
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (launched) {
        dialogueTitle.value = "Action Completed";
        dialogueBody.value = "I've triggered the requested action for you.";
      } else {
        throw Exception("Could not launch $url");
      }
    } catch (e) {
      print("Launch Error: $e");
      dialogueTitle.value = "Action Failed";
      dialogueBody.value = "I'm having trouble opening that specific app ($url). You might need to handle it manually.";
    }
    agentState.value = 0; 
  }

  Future<void> createCalendarEvent(String actionId, dynamic payload) async {
    agentState.value = 2; // Working
    isThinking.value = true;
    currentThought.value = "Setting up your event...";

    try {
      // Payload format: {title, description, start, end}
      final title = payload['title'] ?? "Reminder";
      final description = payload['description'] ?? "";
      final start = DateTime.parse(payload['start'] ?? DateTime.now().toIso8601String());
      final end = DateTime.parse(payload['end'] ?? start.add(const Duration(hours: 1)).toIso8601String());

      final result = await calendarService.createEvent(
        title: title,
        description: description,
        start: start,
        end: end,
      );

      switch (result) {
        case CalendarResult.success:
          dialogueTitle.value = "Event Created";
          dialogueBody.value = "I've added '$title' to your calendar.";
          executeAction(actionId, "Event Created", isSilent: true);
          break;

        case CalendarResult.permissionDenied:
          dialogueTitle.value = "Permission Denied";
          dialogueBody.value = "I can't access your calendar. Please enable permissions in Settings.";
          Future.delayed(const Duration(seconds: 2), () {
            AppSettings.openAppSettings(type: AppSettingsType.settings);
          });
          break;

        case CalendarResult.noCalendars:
          dialogueTitle.value = "No Calendar Found";
          dialogueBody.value = "Your device has no calendar accounts set up. Please open your Calendar app and add an account.";
          
          Future.delayed(const Duration(seconds: 4), () async {
             // Try to open the default calendar app
             // Android: content://com.android.calendar/time/
             // iOS: calshow://
             final url = Uri.parse(
              Theme.of(Get.context!).platform == TargetPlatform.android 
                ? 'content://com.android.calendar/time/' 
                : 'calshow://'
             );
             if (await canLaunchUrl(url)) {
               launchUrl(url);
             }
          });
          break;

        case CalendarResult.error:
          dialogueTitle.value = "Calendar Error";
          dialogueBody.value = "Something went wrong while setting up the event.";
          break;
      }
    } catch (e) {
      print("Calendar Error: $e");
      dialogueTitle.value = "Calendar Error";
      dialogueBody.value = "Something went wrong while setting up the event.";
    }
    
    agentState.value = 0;
    isThinking.value = false;
  }

  String _pendingActionId = "";
  dynamic _pendingPayload = "";

  void submitActionInput(String userInput) {
    if (_pendingActionId.isEmpty) return;
    
    final inputController = Get.find<HomeInputController>();
    inputController.closePanel();
    
    executeAction(_pendingActionId, _pendingPayload, userInput: userInput);
    
    _pendingActionId = "";
    _pendingPayload = "";
    _isImageAnalysisActive = false;
    _isVoiceAnalysisActive = false;
    _isTextAnalysisActive = false;
  }

  void clearAnalysisAndResume() {
    _isImageAnalysisActive = false;
    _isVoiceAnalysisActive = false;
    _isTextAnalysisActive = false;
    
    // Restart priority timer immediately
    _priorityTimer?.cancel();
    _priorityTimer = Timer(const Duration(seconds: 1), () {
      if (!isClosed && !_isImageAnalysisActive && !_isVoiceAnalysisActive && !_isTextAnalysisActive && agentState.value == 0) {
        agentState.value = 2; // Working
        isThinking.value = true;
        dialogueTitle.value = "Working...";
        dialogueBody.value = "Preparing next task.";
        currentThought.value = "Checking for new priorities...";
        update();
        socketService.getPriority();
      }
    });
  }

  void executeAction(String actionId, dynamic payload, {String? userInput, bool isSilent = false}) {
    if (!isSilent) {
      agentState.value = 2; // Move to thinking state
      isThinking.value = true;
      currentThought.value = "On it...";
    }
    
    // Store context for retry 
    _lastActionId = actionId;
    _lastActionPayload = payload;
    _lastUserInput = userInput;

    socketService.approveAction(actionId, payload, userInput: userInput);
  }

  void declineTaskWithId(String actionId, {dynamic payload}) {
    if (actionId == "none") {
      // Just clear and refresh immediately
      agentState.value = 2; // Working
      isThinking.value = true;
      dialogueTitle.value = "Working...";
      dialogueBody.value = "Checking for updates...";
      currentThought.value = "Looking for relevant tasks...";
      update();
      socketService.getPriority();
      return;
    }

    agentState.value = 0; // Show Idle state but with custom message
    isThinking.value = false;
    
    dialogueTitle.value = "Understood";
    dialogueBody.value = "I've got that! I won't ask about this for another hour.";
    update();
    
    socketService.declineAction(actionId, payload: payload);

    // Wait 5 seconds before calling the next priority task
    _priorityTimer?.cancel();
    _priorityTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed && !_isImageAnalysisActive && !_isVoiceAnalysisActive && !_isTextAnalysisActive) {
        agentState.value = 2; // Working
        isThinking.value = true;
        dialogueTitle.value = "Working...";
        dialogueBody.value = "Preparing next task.";
        currentThought.value = "Getting ready for the next task...";
        update();
        socketService.getPriority();
      }
    });
  }

  void approveTask() {
    if (dynamicActions.isEmpty) return;
    handleDynamicAction(dynamicActions[0]);
  }

  void declineTask() {
    if (dynamicActions.isEmpty) return;
    // Look for a decline action, otherwise use the last one
    final declineAction = dynamicActions.firstWhere(
      (a) => a['id'] == 'none' || a['id'] == 'decline', 
      orElse: () => dynamicActions.last
    );
    handleDynamicAction(declineAction);
  }

  void showResultPanel(String actionId, String result) {
    // Open the result view in the sliding panel
    final inputController = Get.find<HomeInputController>();
    inputController.activeChannel.value = InputChannel.result;
    inputController.panelController.open();
  }

  Future<void> processImage(File image) async {
    _isImageAnalysisActive = true;
    _priorityTimer?.cancel(); // Stop any pending priority task fetch

    agentState.value = 2; // Working/Thinking
    isThinking.value = true;
    dialogueTitle.value = "Analyzing Image";
    currentThought.value = "Scanning visual content...";
    update();

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';

      socketService.analyzeImage(base64Image, mimeType);
    } catch (e) {
      print("Image Process Error: $e");
      _isImageAnalysisActive = false;
      agentState.value = 0;
      dialogueTitle.value = "Analysis Failed";
      dialogueBody.value = "I couldn't process that image. Please try again.";
      update();
    }
  }

  Future<void> processVoice(File audio) async {
    _isVoiceAnalysisActive = true;
    _priorityTimer?.cancel();

    agentState.value = 2; // Working/Thinking
    isThinking.value = true;
    dialogueTitle.value = "Analyzing Voice";
    currentThought.value = "Transcribing audio content...";
    update();

    try {
      final bytes = await audio.readAsBytes();
      final base64Audio = base64Encode(bytes);
      final mimeType = lookupMimeType(audio.path) ?? 'audio/m4a';

      socketService.analyzeVoice(base64Audio, mimeType);
    } catch (e) {
      print("Voice Process Error: $e");
      _isVoiceAnalysisActive = false;
      agentState.value = 0;
      dialogueTitle.value = "Analysis Failed";
      dialogueBody.value = "I couldn't process your voice. Please try again.";
      update();
    }
  }

  Future<void> processText(String text) async {
    _isTextAnalysisActive = true;
    _priorityTimer?.cancel();

    agentState.value = 2; // Working/Thinking
    isThinking.value = true;
    dialogueTitle.value = "Analyzing Input";
    currentThought.value = "Processing your message...";
    update();

    try {
      socketService.analyzeText(text);
    } catch (e) {
      print("Text Process Error: $e");
      _isTextAnalysisActive = false;
      agentState.value = 0;
      dialogueTitle.value = "Analysis Failed";
      dialogueBody.value = "I couldn't process your message. Please try again.";
      update();
    }
  }

  @override
  void onClose() {
    socketService.disconnect();
    super.onClose();
  }
}
