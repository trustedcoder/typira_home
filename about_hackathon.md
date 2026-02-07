# About the Project

## Inspiration
It started with a heartbreak. A few years ago, I invited one of my closest friends to my graduation party. We had a long, excited chat about it, and they promised to be there. But on the big day, they never showed up.

When I called them later, they were devastated. They hadn't "flaked"—they had simply forgotten. Our conversation, full of intent and emotion, had been buried under a pile of newer notifications, never making it to their calendar.

That moment of disappointment sparked a realization: **Our phones are smart, but they don't *understand* us.** We generate thousands of words of intent every day—promises to meet, reminders to buy things, ideas for projects—but our keyboards remain passive observers, letting these moments slip through the cracks of the "App Gap."

We built **Typira** to end this disconnect. We asked: *What if your keyboard wasn't just a typewriter, but a partner?* A proactive agent that lives where you do, understands the *who, what, and where* of your life, and ensures that when you say "I'll be there," your phone actually makes it happen.

## What it does
Typira is an **agentic AI keyboard** that replaces your default mobile keyboard. It acts as a "Digital Twin" that proactively unblocks your workflows:
1.  **Passive Context Building:** As you type, Typira uses Gemini to continuously update a dynamic, private **User Bio**. It learns your schedule, your tone, your projects, and your stress levels.
2.  **Proactive Orchestration:** It doesn't just wait for you to ask. If you agree to a meeting in WhatsApp, Typira proactively offers to add it to your calendar. If you mention a location, it offers to open Maps.
3.  **Multimodal Interaction:** You can speak or snap photos directly from the keyboard, and Typira uses Gemini's multimodal capabilities to extract context and trigger actions.
4.  **Background Intelligence:** Even when you aren't typing, Typira's backend "Ghost Agent" processes your history to find relevant news, updates, or missed tasks, surfacing them as actionable notifications.

## How we built it
We built Typira as a seamless bridge between a high-performance mobile frontend and a powerful Agentic backend.

### The "Edge" (Mobile App & Keyboard)
*   **Flutter (Dart):** Chosen for its cross-platform capabilities to run on both iOS and Android.
*   **Custom Keyboard Extension:** We built a custom keyboard from scratch that intercepts text input and renders a dynamic "Agent UI" instead of just predictive text.
*   **Deep Linking Engine:** We utilized `android_intent_plus` and `url_launcher` to construct a library of deep links (`geo:`, `content:`, `mailto:`) that allow the keyboard to "control" other apps.
*   **Multimodal Inputs:** Integrated `record` for voice and `image_picker` for camera inputs to feed Gemini's multimodal models.

### The "Brain" (Backend)
*   **Python (Flask):** The orchestrator of our agentic logic.
*   **Google Gemini 3 (via `google-genai`):** The core intelligence. We use Gemini not just for text generation, but for **reasoning**. We feed it the user's `TypingHistory` and `UserBio` to generate structured JSON plans (Thoughts -> Actions).
*   **Real-time Sockets (`socket_io`):** To minimize latency between the keyboard keystrokes and the AI's "thought stream."
*   **Background Scheduler (`apscheduler`):** Powering the "Ghost Agent" that runs periodic checks on user context to generate asynchronous insights.

## Challenges we ran into
*   **The "Context Balance"**: Passing *too much* typing history to the LLM introduced noise and latency. We had to engineer a "Memory Distillation" process where raw typing data is periodically summarized into the structured `User Bio`, keeping the active context window lean but highly relevant.
*   **Keyboard Extension Limits**: iOS and Android impose strict memory and network limits on keyboard extensions. We had to offload heavy processing to the main app container or the cloud backend to prevent the keyboard from crashing.
*   **Latency vs. Intelligence**: Users expect keyboards to be instant. Waiting for an LLM response for every keystroke is impossible. We implemented an optimistic UI where the keyboard functions instantly as a typing tool, while the AI "Agent Layer" runs asynchronously, updating the UI only when it has a valid "thought" or "action."

## Accomplishments that we're proud of
*   **The "User Bio" Engine**: Watching the system accurately deduce "You seem stressed about your startup launch" purely from typing patterns in unrelated apps was a "magic moment."
*   **True Multimodality**: Successfully piping voice and clear image context from a keyboard interface directly into Gemini's reasoning loop.
*   **Proactive "Thought Stream"**: moving away from a black-box chatbot to a UI that shows the user *what* the agent is thinking ("Checking calendar...", "Found a conflict...") before it acts.

## What we learned
*   **Proactivity is Key**: An agent that waits for commands is just a tool. An agent that *anticipates* needs is a partner.
*   **The Keyboard is the Ultimate Context**: No other app has permission to see what you do in *every* other app. It is the perfect home for a personal AI agent.

## What's next for Typira
*   **Local-First Intelligence**: Moving the "User Bio" updating logic to on-device Gemini Nano models for enhanced privacy and zero latency.
*   **"Marathon" Context**: expanding the backend to handle days or weeks of context for even deeper long-term planning.
*   **Universal Action Graph**: Building a community-contributed library of Deep Links to support thousands of apps (Spotify, Uber, Doordash) out of the box.

## Built with
*   **Mobile Framework**: Flutter 3.8, Dart
*   **Languages**: Python, Dart, Swift, Kotlin
*   **AI Intelligence**: Google Gemini 3 (via `google-genai`), Gemini Flash 2.0 (Preview)
*   **Backend**: Flask, Flask-SocketIO, APScheduler
*   **Database**: MySQL (SQLAlchemy), Firebase (FCM)
*   **Key Mobile Libraries**:
    *   `android_intent_plus` & `url_launcher` (Deep Linking)
    *   `socket_io_client` (Real-time Latency)
    *   `record` & `image_picker` (Multimodal Inputs)
    *   `device_calendar` (Calendar Integration)
*   **Infrastructure**: Google Cloud Platform, Firebase
