import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typira/storage/session_manager.dart';
import '../activities/home_activity.dart'; // Navigate to Home
import '../constants/app_theme.dart';
import '../helpers/route.dart';

class IntroContent {
  final String title;
  final String description;
  final String lottieAsset;

  IntroContent({required this.title, required this.description, required this.lottieAsset});
}

class IntroController extends GetxController {
  var currentPage = 0.obs;
  final pageController = PageController();

  final List<IntroContent> contents = [
    IntroContent(
      title: "I Live Where You Type",
      description: "From emails to notes, I am your omnipresent keyboard companion. I see what you write and help you craft it better.",
      lottieAsset: "assets/lottie/social_media_network.json", // Placeholder
    ),
    IntroContent(
      title: "I Know Your Context",
      description: "I remember your projects, your tone, and your goals. No need to explain things twice.",
      lottieAsset: "assets/lottie/brain.json", // Placeholder
    ),
    IntroContent(
      title: "I Act On Your Behalf",
      description: "I don't just chat. I draft plans, update records, and provide insights. I am your Agent, not just a bot.",
      lottieAsset: "assets/lottie/agent.json", // Placeholder
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void next() {
    if (currentPage.value < contents.length - 1) {
      pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      finishIntro();
    }
  }

  Future<void> finishIntro() async {
    SessionManager.setSeenIntro(true);
    checkLoginStatus();
  }

  void checkLoginStatus(){
    if(SessionManager.isLoggedIn()){
      RouteConfig.navigateToReplacePage("/home");
    }
    else{
      RouteConfig.navigateToReplacePage("/login");
    }
  }
}
