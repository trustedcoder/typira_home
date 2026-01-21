import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../api/authentication.dart';
import '../helpers/alert_dialog.dart';
import '../helpers/progressmodal.dart';
import '../storage/session_manager.dart';

class LoginController extends GetxController {
  final authenticationApi = Authentication();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();


  @override
  void onInit() async {
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> loginUser({required String email, required String password}) async {
    ProgressDialog progressDialog = ProgressDialog(message: "Please wait...");
    Get.dialog(progressDialog, barrierDismissible: false);
    try {
      authenticationApi.login(
          email: email,
          password: password)
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

  void login() {
    final email = emailController.text;
    final password = passwordController.text;

    loginUser(
        email: email,
        password: password
    );
  }
}
