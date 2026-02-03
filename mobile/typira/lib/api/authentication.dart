import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart'; // Import Get for navigation
import '../activities/login_activity.dart';
import '../constants/app_config.dart';
import 'api_client.dart'; // Import LoginActivity

class Authentication {
  final ApiClient _client = ApiClient(
    http.Client(),
    [LoggingInterceptor()],
    onUnauthorized: () {
      Get.offAll(() => const LoginActivity()); // Redirect to login page
    },
  );

  Future<dynamic> login({required String email, required String password, String? fcm_token}) async {
    final payload = {
      "email": email,
      "password": password,
      "fcm_token": fcm_token
    };

    final request = http.Request('POST', Uri.parse(AppConfig.login))
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode(payload);

    try {
      final response = await _client.send(request);
      final responseBody = await response.stream.bytesToString();
      print(responseBody);
      if (response.statusCode != 200) {
        return json.decode(responseBody);
      } else {
        return json.decode(responseBody);
      }
    } catch (exception) {
      print(exception.toString());
      return Future.error(exception.toString());
    }
  }

  Future<dynamic> register({required String name,required String email, String? fcm_token, required String password}) async {
    final payload = {
      "email": email,
      "password": password,
      "name": name,
      "fcm_token": fcm_token
    };

    final request = http.Request('POST', Uri.parse(AppConfig.register))
      ..headers['Content-Type'] = 'application/json'
      ..body = json.encode(payload);

    try {
      final response = await _client.send(request);
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode != 200) {
        return json.decode(responseBody);
      } else {
        return json.decode(responseBody);
      }
    } catch (exception) {
      print(exception.toString());
      return Future.error(exception.toString());
    }
  }

  Future<dynamic> deleteAccount() async {
    final request = http.Request('DELETE', Uri.parse(AppConfig.delete_account))
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

  Future<dynamic> clearMemory() async {
    final request = http.Request('DELETE', Uri.parse(AppConfig.clear_memory))
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