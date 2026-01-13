import 'package:get/get.dart';
import 'package:flutter/material.dart';

class MemoryItem {
  final String title;
  final String timestamp;
  final String type; // 'text', 'plan', 'image', 'voice'
  final String contentSnippet;
  final String fullContent; // Markdown supported
  final String? mediaPath; // Local path or URL
  final IconData icon;
  final Color color;

  MemoryItem({
    required this.title,
    required this.timestamp,
    required this.type,
    required this.contentSnippet,
    this.fullContent = "",
    this.mediaPath,
    required this.icon,
    required this.color,
  });
}

class MemoryController extends GetxController {
  
  var memoryItems = <MemoryItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadMockData();
  }

  void loadMockData() {
    memoryItems.value = [
      MemoryItem(
        title: "Weekly Report Draft",
        timestamp: "2 mins ago",
        type: "text",
        contentSnippet: "Summary of Q3 performance...",
        fullContent: "# Weekly Report - Q3\n\n**Performance Summary**\nOverall, the team has exceeded expectations by 15%.\n\n*   **Revenue**: \$1.2M (+12% YoY)\n*   **User Growth**: 50k new users\n\n## Next Steps\nFocus on retention strategies for the holiday season.",
        icon: Icons.article,
        color: const Color(0xFF2979FF),
      ),
      MemoryItem(
        title: "Project Alpha Plan",
        timestamp: "1 hr ago",
        type: "plan",
        contentSnippet: "Step 1: Research Competitors...",
        fullContent: "# Project Alpha Execution Plan\n\n1.  **Phase 1: Research**\n    *   Analyze top 3 competitors.\n    *   Survey 100 potential users.\n2.  **Phase 2: MVP**\n    *   Build core 'Agent Core' feature.\n    *   Internal beta testing.",
        icon: Icons.checklist,
        color: const Color(0xFF00E5FF),
      ),
      MemoryItem(
        title: "Voice Note Analysis",
        timestamp: "Yesterday",
        type: "voice",
        contentSnippet: "Meeting with design team...",
        fullContent: "**Transcript Summary:**\n\nThe design team discussed the need for a 'Dark Mode' first approach. \n\n> \"We want the agent to feel like a nocturnal companion.\"\n\n**Action Items:**\n*   Update color palette to Slate/Neon.\n*   Refine glassmorphism values.",
        icon: Icons.mic,
        color: const Color(0xFFD500F9),
      ),
      MemoryItem(
        title: "Whiteboard Scan",
        timestamp: "Yesterday",
        type: "image",
        contentSnippet: "Architecture diagram V2...",
        fullContent: "Analyzed the whiteboard structure. Identified 3 main modules:\n1.  User Input\n2.  Agent Core (Processing)\n3.  Output Rendering\n\n*See attached image for details.*",
        icon: Icons.image,
        color: const Color(0xFF00E676),
      ),
    ];
  }
}
