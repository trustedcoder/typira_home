import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_theme.dart';
import '../controllers/login.dart';
import '../helpers/route.dart';

class LoginActivity extends StatelessWidget {

  const LoginActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = Get.put(LoginController());

    // Set the status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make the status bar transparent
      statusBarIconBrightness: Brightness
          .light, // Use light icons for dark backgrounds
    ));

    return Scaffold(
      body: SafeArea(
          child: Container(
            color: AppTheme.whiteColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Text("Login",
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 8.h),
                  child: Text("Your personal assistant that lives on your keyboard.",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),

                Container(
                  margin: EdgeInsets.all(12.w),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGrayColor,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text("Email",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4.h, bottom: 12.h),
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: AppTheme.whiteColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: TextField(
                          controller: loginController.emailController,
                          style: Theme.of(context).textTheme.labelSmall,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: "Enter email",
                            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textColor),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text("Password",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                        ],
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4.h),
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        decoration: BoxDecoration(
                          color: AppTheme.whiteColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: TextField(
                          controller: loginController.passwordController,
                          style: Theme.of(context).textTheme.labelSmall,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: "Enter Your Password",
                            hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textColor),
                            border: InputBorder.none,
                          ),
                          obscureText: true,
                        ),
                      ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.end,
                      //   children: [
                      //     InkWell(
                      //       onTap: (){
                      //         RouteConfig.navigateToReplacePage("/forgot_pass");
                      //       },
                      //       child: Container(
                      //           padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                      //           child: Text("Forgot Password?",
                      //             style: TextStyle(
                      //               color: AppTheme.textColor,
                      //               fontSize: 14.sp,
                      //               fontWeight: FontWeight.w600,
                      //             ),
                      //           )),
                      //     )
                      //   ],
                      // ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: EdgeInsets.symmetric(horizontal: 100.w),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                onPressed: () {
                                  // Handle login logic here
                                  loginController.login();
                                },
                                child: Text('Login',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.whiteColor),
                              )
                          )
                          )],
                      ),
                      SizedBox(height: 8.h),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Not Member?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.grayColor),
                            ),
                            TextSpan(
                              text: ' Sign Up',
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  RouteConfig.navigateToReplacePage("/register");
                                  },
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
      ),
    );
  }

}
