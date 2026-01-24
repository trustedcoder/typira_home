import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants/app_config.dart';
import 'api_client.dart';
import 'package:get/get.dart';
import '../activities/login_activity.dart';

class InsightsApi {
  final ApiClient _client = ApiClient(
    http.Client(),
    [LoggingInterceptor()],
    onUnauthorized: () {
      Get.offAll(() => const LoginActivity());
    },
  );

  Future<dynamic> getInsightsStats() async {
    final request = http.Request('GET', Uri.parse(AppConfig.getInsightsStats))
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
