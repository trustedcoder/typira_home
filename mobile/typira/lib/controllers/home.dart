import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class HomeController extends GetxController {
  
  // Agent State
  var isOffline = false.obs;
  var isThinking = false.obs;
  
  // Navigation State
  var tabIndex = 0.obs;

  // Conversation/Box State
  // 0: Proposal (User input needed)
  // 1: Working (Showing internal monologue)
  // 2: Idle/Searching (Background processing)
  var agentState = 0.obs; 
  
  // Dynamic Content
  var dialogueTitle = "I've analyzed your schedule.".obs;
  var dialogueBody = "You have a busy afternoon. Would you like me to draft your weekly report ahead of time?".obs;
  var currentThought = "".obs; // For the "Working" state

  @override
  void onInit() {
    super.onInit();
    // Start with the initial proposal
  }

  // Interaction: "Yes, draft it"
  void startDrafting() async {
    agentState.value = 1; // Switch to Working View
    isThinking.value = true;
    
    // Simulate Agentic Steps
    await _updateThought("Analyzing recent email patterns...");
    await _updateThought("Structuring report outline...");
    await _updateThought("Drafting content section...");
    await _updateThought("Verifying tone consistency...");
    
    isThinking.value = false;
    showDraftResult("Weekly Report", "Subject: Weekly Report\n\nHi Team,\n\nThis week we successfully deployed the new Agent Core. Performance metrics are up by 15%.\n\nBest,\nCelestine");
    
    // After result, go back to searching
    startBackgroundSearch();
  }

  // Interaction: "Not yet" (Decline)
  void declineProposal() {
    startBackgroundSearch();
  }

  void startBackgroundSearch() async {
    agentState.value = 1; // Use the working view to show "Background thinking"
    isThinking.value = true;
    
    // Simulate "Living" Agent
    await _updateThought("Understood. Filing for later.");
    await _updateThought("Scanning calendar for other conflicts...");
    await _updateThought("Reviewing recent notes...");
    
    // Propose something new
    isThinking.value = false;
    agentState.value = 0; // Back to Proposal
    dialogueTitle.value = "Found a new opportunity";
    dialogueBody.value = "I noticed you have a meeting with Design at 3 PM. Should I prepare a summary of last week's design critique?";
  }

  Future<void> _updateThought(String thought) async {
    currentThought.value = thought;
    await Future.delayed(const Duration(seconds: 2));
  }

  void showDraftResult(String title, String content) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Result: $title",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                content,
                style: const TextStyle(color: Colors.white70, fontFamily: 'Courier'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27AF4D)),
                    onPressed: () => Get.back(),
                    child: const Text("Copy & Close", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
