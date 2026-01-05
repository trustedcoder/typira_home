import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../constants/app_theme.dart';
import '../controllers/register.dart';
import 'login_activity.dart';

class RegisterActivity extends StatelessWidget {
  const RegisterActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final registerController = Get.put(RegisterController());

    // Set the status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Make the status bar transparent
      statusBarIconBrightness:
          Brightness.light, // Use light icons for dark backgrounds
    ));

    return Scaffold(
      body: SafeArea(
        child: Container(
          color: AppTheme.whiteColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Text(
                  "Register",
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 8.h),
                child: Text(
                  "Book your service at any time and anywhere.",
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
                        Text(
                            "Name",
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
                        controller: registerController.nameController,
                        style: Theme.of(context).textTheme.labelSmall,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Enter Name",
                          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textColor),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                            "Email",
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
                        controller: registerController.emailController,
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
                        Text(
                            "Password",
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
                        controller: registerController.passwordController,
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

                    Row(
                      children: [
                        Text(
                            "Confirm Password",
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
                        controller:
                            registerController.passwordConfirmationController,
                        style: Theme.of(context).textTheme.labelSmall,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: "Enter Confirm Password",
                          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textColor),
                          border: InputBorder.none,
                        ),
                        obscureText: true,
                      ),
                    ),
                    Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: registerController.agreeWithTerms.value,
                          onChanged: (value) {
                            registerController.agreeWithTerms.value = value!;
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        Text(
                          "Agree with terms and condition",
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      ],
                    )),
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
                            registerController.register();
                          },
                          child: Text(
                            'Register',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.whiteColor),
                          ),
                        ))
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Already a Member?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.grayColor),
                            ),
                            TextSpan(
                              text: ' Sign In',
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.to(() => const LoginActivity());
                                },
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ),
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
