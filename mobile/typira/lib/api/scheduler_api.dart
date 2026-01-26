import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_config.dart';
import 'api_client.dart';
import 'package:get/get.dart';
import '../activities/login_activity.dart';

class SchedulerApi {
  final ApiClient _client = ApiClient(
    http.Client(),
    [LoggingInterceptor()],
    onUnauthorized: () {
      Get.offAll(() => const LoginActivity());
    },
  );

  Future<dynamic> getSchedules() async {
    final request = http.Request('GET', Uri.parse(AppConfig.scheduler))
      ..headers['Content-Type'] = 'application/json';

    return _sendRequest(request);
  }

  Future<dynamic> createSchedule(Map<String, dynamic> data) async {
    final request = http.Request('POST', Uri.parse(AppConfig.scheduler))
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode(data);

    return _sendRequest(request);
  }

  Future<dynamic> updateSchedule(int id, Map<String, dynamic> data) async {
    final request = http.Request('PUT', Uri.parse("${AppConfig.scheduler}$id"))
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode(data);

    return _sendRequest(request);
  }

  Future<dynamic> deleteSchedule(int id) async {
    final request = http.Request('DELETE', Uri.parse("${AppConfig.scheduler}$id"))
      ..headers['Content-Type'] = 'application/json';

    return _sendRequest(request);
  }

  Future<dynamic> _sendRequest(http.BaseRequest request) async {
    try {
      final response = await _client.send(request);
      final responseBody = await response.stream.bytesToString();
      return json.decode(responseBody);
    } catch (exception) {
      print(exception.toString());
      return Future.error(exception.toString());
    }
  }
}
