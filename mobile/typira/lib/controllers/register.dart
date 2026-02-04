import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../api/authentication.dart';
import '../helpers/alert_dialog.dart';
import '../helpers/progressmodal.dart';
import '../storage/session_manager.dart';
import '../services/notification.dart';

class RegisterController extends GetxController {
  final authenticationApi = Authentication();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  var countryCode = '+386'.obs;
  var agreeWithTerms = false.obs;
  final TextEditingController passwordConfirmationController = TextEditingController();


  Future<void> registerUser({required String name,required String email, String? fcm_token, required String password}) async {
    ProgressDialog progressDialog = ProgressDialog(message: "Please wait...");
    Get.dialog(progressDialog, barrierDismissible: false);
    try {
      authenticationApi.register(
          name: name,
          email: email,
          password: password,
          fcm_token: fcm_token)
          .then((resp) {
        Get.back();
        print(resp);
        if (resp['status'] == 1) {
          SessionManager.setAuth(resp['authorization']);
          SessionManager.setLoggedIn(true);
          SessionManager.setUserName(resp['name']);
          Get.offAllNamed("/home");
        }
        else {
          AlertDialogCustom.show(Get.context!, "Alert!", resp['message'], "OK");
        }
      }, onError: (err) {
        Get.back();
        AlertDialogCustom.show(Get.context!, "Alert!",
            "There was an error while connecting to the server.\nPlease try again later.",
            "OK");
      });
    } catch (exception) {
      Get.back();
      AlertDialogCustom.show(Get.context!, "Alert!",
          "There was an error while connecting to the server.", "OK");
    }
  }

  void register() async {
    final name = nameController.text;
    final email = emailController.text;
    String? fcm_token = await NotificationService.getFcmToken();
    final password = passwordController.text;
    final passwordConfirmation = passwordConfirmationController.text;

    if(agreeWithTerms.value == false) {
      AlertDialogCustom.show(Get.context!, "Alert", 'You must agree with terms and conditions', 'OKAY');
      return;
    }

    if(password != passwordConfirmation) {
      AlertDialogCustom.show(Get.context!, "Alert", 'Password do not match', 'OKAY');
      return;
    }

    registerUser(
        name: name,
        email: email,
        fcm_token: fcm_token,
        password: password
    );
  }
}