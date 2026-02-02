import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:io';
import '../constants/app_config.dart';
import '../storage/session_manager.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? socket;
  
  // Callbacks
  Function(Map<String, dynamic>)? onPriorityTask;
  Function(String)? onThoughtUpdate;
  Function(Map<String, dynamic>)? onActionResult;
  Function(bool)? onConnectionStatus;
  Function()? onConnecting;
  Function(dynamic)? onConnectError;
  Function(dynamic)? onConnectTimeout;

  void connect() {
    final token = SessionManager.getAuth();
    
    print('SocketService: connect() called');
    final url = '${AppConfig.socketUrl}/home';
    print('SocketService: Connecting to $url');
    print('SocketService: Token being used: ${token?.substring(0, 5)}...');

    socket = io.io(url, 
      io.OptionBuilder()
        .setTransports(['websocket'])
        .setExtraHeaders({'Authorization': 'Bearer $token'})
        .enableAutoConnect()
        .setReconnectionAttempts(5) // Retry a few times
        .enableMultiplex()
        .build()
    );

    print('SocketService: Socket instance created. Connected? ${socket?.connected}');

    socket!.on('connecting', (_) {
      print('SocketService: Connecting event fired...');
      onConnecting?.call();
    });

    socket!.onConnect((_) {
      print('SocketService: Connected to Socket Successfully');
      onConnectionStatus?.call(true);
    });



    socket!.onDisconnect((_) {
      print('SocketService: Disconnected from Socket');
      onConnectionStatus?.call(false);
    });

    socket!.onConnectError((data) {
      print('SocketService: Connect Error: $data');
      onConnectError?.call(data);
      onConnectionStatus?.call(false);
    });

    socket!.on('error', (data) {
      print('SocketService: Generic Error: $data');
    });

    socket!.on('connect_timeout', (data) {
      print('SocketService: Connect Timeout: $data');
      onConnectTimeout?.call(data);
      onConnectionStatus?.call(false);
    });

    socket!.on('priority_task', (data) {
      if (data is Map<String, dynamic>) {
        onPriorityTask?.call(data);
      }
    });

    socket!.on('thought_update', (data) {
      if (data != null && data['text'] != null) {
        onThoughtUpdate?.call(data['text']);
      }
    });

    socket!.on('action_result', (data) {
      if (data is Map<String, dynamic>) {
        onActionResult?.call(data);
      }
    });
  }

  void getPriority() {
    socket?.emit('get_priority', {
      'platform': Platform.isIOS ? 'ios' : 'android'
    });
  }

  void approveAction(String actionId, dynamic payload, {String? userInput}) {
    socket?.emit('approve_action', {
      'action_id': actionId,
      'payload': payload,
      'user_input': userInput,
      'platform': Platform.isIOS ? 'ios' : 'android'
    });
  }

  void declineAction(String actionId, {dynamic payload}) {
    socket?.emit('decline_action', {
      'action_id': actionId,
      'payload': payload,
      'platform': Platform.isIOS ? 'ios' : 'android'
    });
  }

  void analyzeImage(String base64Image, String mimeType) {
    socket?.emit('analyze_image', {
      'image': base64Image,
      'mime_type': mimeType,
      'platform': Platform.isIOS ? 'ios' : 'android'
    });
  }

  void analyzeVoice(String base64Audio, String mimeType) {
    socket?.emit('analyze_voice', {
      'audio': base64Audio,
      'mime_type': mimeType,
      'platform': Platform.isIOS ? 'ios' : 'android'
    });
  }

  void analyzeText(String text) {
    socket?.emit('analyze_text', {
      'text': text,
      'platform': Platform.isIOS ? 'ios' : 'android'
    });
  }

  void disconnect() {
    socket?.disconnect();
  }
}
