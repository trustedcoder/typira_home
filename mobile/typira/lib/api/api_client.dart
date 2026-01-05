import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../storage/session_manager.dart'; // For VoidCallback

abstract class Interceptor {
  FutureOr<http.BaseRequest> beforeRequest(http.BaseRequest request);
  FutureOr<http.Response> afterResponse(http.Response response);
  FutureOr<void> onError(dynamic error);
}

class ApiClient extends http.BaseClient {
  final http.Client _inner;
  final List<Interceptor> _interceptors;
  final VoidCallback onUnauthorized;

  ApiClient(this._inner, this._interceptors, {required this.onUnauthorized});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      // Add headers globally
      request.headers['Accept'] = 'application/json';

      final token = SessionManager.getAuth();

      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      for (var interceptor in _interceptors) {
        request = await interceptor.beforeRequest(request);
      }
      final response = await _inner.send(request);
      final streamedResponse = await http.Response.fromStream(response);

      // Global 401 handler
      if (streamedResponse.statusCode == 401) {
        onUnauthorized();
      }

      http.Response modifiedResponse = streamedResponse;
      for (var interceptor in _interceptors.reversed) {
        modifiedResponse = await interceptor.afterResponse(modifiedResponse);
      }

      return http.StreamedResponse(
        Stream.value(modifiedResponse.bodyBytes),
        modifiedResponse.statusCode,
        contentLength: modifiedResponse.contentLength,
        headers: modifiedResponse.headers,
        isRedirect: modifiedResponse.isRedirect,
        persistentConnection: modifiedResponse.persistentConnection,
        reasonPhrase: modifiedResponse.reasonPhrase,
        request: modifiedResponse.request,
      );
    } catch (e) {
      for (var interceptor in _interceptors.reversed) {
        await interceptor.onError(e);
      }
      rethrow;
    }
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  FutureOr<http.BaseRequest> beforeRequest(http.BaseRequest request) {
    print('--> ${request.method} ${request.url}');
    print('Headers: ${request.headers}');
    if (request is http.Request) {
      print('Body: ${request.body}');
    }
    return request;
  }

  @override
  FutureOr<http.Response> afterResponse(http.Response response) {
    return response;
  }

  @override
  FutureOr<void> onError(dynamic error) {
    print('Error: $error');
  }
}
