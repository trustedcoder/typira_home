# Typira - Gemini 3 Hackathon Video Script

**Target Duration:** ~2:45 - 3:00 minutes
**Goal:** Showcase Typira as a context-aware, multimodal agentic AI personal assistant powered by Gemini 3.

## Script Overview
1.  **The Hook (0:00 - 0:30):** The problem (information overload) vs. Typira's solution (Contextual Agency).
2.  **The Core: Agentic Keyboard (0:30 - 1:00):** Gathering context passively and updating the **User Bio**.
3.  **Multimodal Demo (1:00 - 1:30):** Voice and Camera interaction.
4.  **The "Brain" (Backend) (1:30 - 2:00):** Visualizing the Gemini 3 logic.
5.  **Deep Personalization (2:00 - 2:30):** **Background Tasks** and **Scheduled Insights** based on accumulated context.
6.  **Closing (2:30 - 3:00):** Summary and Call to Action.

---

## Detailed Breakdown

### Scene 1: The Hook (0:00 - 0:30)

| Time | Visual (Screen) | Audio (Voiceover) |
| :--- | :--- | :--- |
| **0:00** | **[Shot of a busy phone screen]** Notifications piling up, multiple apps open. Chaotic energy. | "Every day, you type thousands of words—across social media, emails, and notes. But does your phone actually *understand* you across all those apps?" |
| **0:10** | **[Cut to Typira Home Screen]** Clean, minimal, "Premium" dark mode UI. A soothing gradient pulse. | "Meet Typira. Not just another chatbot, but a fully agentic personal assistant integrated into your keyboard." |
| **0:20** | **[Zoom in on "Priority Task"]** The app effectively showing *one* single critical task. | "Typira uses Gemini 3's massive context window to understand your entire history, filtering out the noise to focus on what matters *right now*." |

### Scene 2: The Core - Agentic Keyboard & Bio (0:30 - 1:00)

| Time | Visual (Screen) | Audio (Voiceover) |
| :--- | :--- | :--- |
| **0:30** | **[Close up of typing in WhatsApp/Notes]** The user is typing on the **Typira Keyboard**. It looks sleek and integrated. | "Context isn't just about what you tell an app. It's about where you *are* and what you *do*." |
| **0:40** | **[Animation]** Subtle particles flow from the keyboard into a "Bio" icon. Transition to **User Bio Screen** showing dynamic fields: *"Likely a night owl"*, *"Working on a startup"*, *"Stressed about deadline"*. | "Typira lives in your keyboard. As you type, it passively learns to **write like you** and **think like you**. It builds a **digital bio** of you. It understands your habits, your schedule, and even your stress levels." |
| **0:50** | **[Screen shows a Suggestion]** The keyboard pop-up suggests: *"Add to Calendar?"* based on the context. | "It doesn't just watch; it assists. Understanding your intent in real-time, whether you're in a chat, an email, or a note." |

### Scene 3: Multimodal Interaction (1:00 - 1:30)

| Time | Visual (Screen) | Audio (Voiceover) |
| :--- | :--- | :--- |
| **1:00** | **[User taps Microphone using the Keyboard toolbar]** Speech waveform animation. User speaks: *"Remind me to buy groceries for the party."* | "When typing isn't enough, Typira listens..." |
| **1:10** | **[Split Screen]** Left: App showing the transcript. Right: **Backend Log** showing `GeminiBusiness.analyze_voice`. | "...using Gemini 3's native multimodal capabilities to instantly process voice without brittle external transcribers." |
| **1:20** | **[User taps Camera via Keyboard]** Takes a photo of a messy desk with a bill. User types: *"File this."* | "It sees. We can snap a photo..." |
| **1:25** | **[App Screen]** A "Memory" card appears: *"Filed electric bill from photo."* | "...and Typira doesn't just describe the photo; it extracts the context that matters to *you*, storing it in your long-term memory." |

### Scene 4: The "Brain" - Agentic Reasoning (1:30 - 2:00)

| Time | Visual (Screen) | Audio (Voiceover) |
| :--- | :--- | :--- |
| **1:30** | **[Transition to "The Matrix" view]** A scrolling terminal showing JSON output from `analyze_context`. Highlight "thoughts" and "plan". | "But the real magic happens here. This isn't a simple command-response loop." |
| **1:40** | **[Highlight "Chain of Thought"]** Zoom in on JSON: `thoughts: ["User is stressed", "Action priority is high", "Suggesting rescheduling"]`. | "Typira engages in multi-step reasoning. It assesses your emotional state from your tone, checks your schedule, and formulates a plan *before* acting." |
| **1:50** | **[Mobile Screen]** The App proactively suggests: *"You seem busy. Want to push your 3 PM meeting?"* | "It doesn't just wait for commands. It anticipates needs, shifting from reactive to proactive." |

### Scene 5: Background Insights (2:00 - 2:30)

| Time | Visual (Screen) | Audio (Voiceover) |
| :--- | :--- | :--- |
| **2:00** | **[Screen shows "Scheduled Insight"]** A card pops up: *"Startup Funding News"*. | "And even when you're asleep, Typira is working." |
| **2:10** | **[Clicking the card]** Expands to show a summary of news relevant to the user's "Startup" bio project. | "Using background scheduled tasks, it connects your **User Bio**, **Typing History**, and **Memories** to the outside world." |
| **2:20** | **[Split Screen: Code & UI]** Show `GoogleSearchRetrieval` code alongside the Insight card. | "It proactively fetches relevant news, updates, or deep knowledge, so you wake up to insights, not just noise." |

### Scene 6: Conclusion (2:30 - 3:00)

| Time | Visual (Screen) | Audio (Voiceover) |
| :--- | :--- | :--- |
| **2:30** | **[Montage]** Fast cuts of: Writing an email with `suggest_text`, Voice command, Dark mode UI. | "Typira isn't just an app; it's a fundamental shift in how we interact with our devices." |
| **2:45** | **[Shot of both Android and iPhone devices]** Typira logo appears over both. "Available on Android and iOS" text. | "A personal assistant that lives where you do, learns as you type, and acts before you ask. Experience the power of Typira, available now on both Android and iOS." |

---

## Production Notes

*   **Platform:** Record the mobile app on an emulator/simulator.
*   **Key Visual:** Make sure the **Bio Screen** is clearly visible in Scene 2 to show the "learning" aspect.
*   **Backend:** Use a terminal with a cool theme (e.g., Matrix green or Cyberpunk neon) to show the python logs.
*   **Music:** Upbeat, modern, slightly futuristic Lofi or Synthwave.
*   **Tools Used:** Gemini 3 Flash Preview, Flutter, Python/Flask Backend.
