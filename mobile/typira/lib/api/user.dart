import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'dart:convert';

import '../constants/app_config.dart';

class UserApi {
  Future updateUser({required String token, required String fcm_token, required String device_info, File? image_file}) async {
    Map<String, String> requestHeaders = {
      'Accept': 'application/json',
      'Content-Type': 'multipart/form-data',
      "authorization": token
    };

    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse(AppConfig.getUser),
      );


      if (image_file != null) {
        var mimeType = lookupMimeType(image_file.path) ?? 'application/octet-stream';
        request.files.add(
          http.MultipartFile(
            'image_file',
            image_file.openRead(),
            await image_file.length(),
            filename: basename(image_file.path),
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      request.fields['fcm_token'] = fcm_token;
      request.fields['device_info'] = device_info;
      request.headers.addAll(requestHeaders);

      final response = await request.send();

      if (response.statusCode == 200) {
        return json.decode(await response.stream.bytesToString());
      }
      else if(response.statusCode == 401) {
        return json.decode(await response.stream.bytesToString());
      }
      else if(response.statusCode == 413) {
        return Future.error("Image size too large");
      }
      else{
        return Future.error("Server error");
      }
    } catch (exception) {
      return Future.error(exception.toString());
    }
  }
}