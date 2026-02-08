import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_config.dart';
import 'api_client.dart';
import 'package:get/get.dart';
import '../activities/login_activity.dart';

class MemoryApi {
  final ApiClient _client = ApiClient(
    http.Client(),
    [LoggingInterceptor()],
    onUnauthorized: () {
      Get.offAll(() => const LoginActivity());
    },
  );

  Future<dynamic> getMemories(int page, {int perPage = 20}) async {
    return _fetchPaginated(AppConfig.getMemories, page, perPage);
  }

  Future<dynamic> getTypingHistory(int page, {int perPage = 20}) async {
    return _fetchPaginated(AppConfig.getTypingHistory, page, perPage);
  }

  Future<dynamic> getUserActions(int page, {int perPage = 20}) async {
    return _fetchPaginated(AppConfig.getUserActions, page, perPage);
  }

  Future<dynamic> getMemoryDetail(String id) async {
    final uri = Uri.parse("${AppConfig.getMemory}/$id");
    final request = http.Request('GET', uri)
      ..headers['Content-Type'] = 'application/json';

    try {
      final response = await _client.send(request);
      final responseBody = await response.stream.bytesToString();
      return json.decode(responseBody);
    } catch (exception) {
      print(exception.toString());
      return Future.error(exception.toString());
    }
  }

  Future<dynamic> _fetchPaginated(String url, int page, int perPage) async {
    final uri = Uri.parse(url).replace(queryParameters: {
      'page': page.toString(),
      'per_page': perPage.toString(),
    });

    final request = http.Request('GET', uri)
      ..headers['Content-Type'] = 'application/json';

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
