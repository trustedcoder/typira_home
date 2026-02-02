# Typira Screen Recording Guide

Follow this guide to capture the screen recordings mentioned in the video script (`video_script.md`).

## Prerequisites
1.  **Run the seeding script:** `python backend_api/typira/seed_db.py`
2.  **Login as Demo User:** Use `demo@typira.ai` and `password123`.
3.  **Prepare Apps:** Have WhatsApp/Notes and a cool Terminal theme ready.

---

## Timestamps & Interactions

### Scene 1: The Hook (0:10 - 0:30)
- **0:10 - [Cut to Typira Home Screen]**
    - **Instruction:** Open the Typira app. Ensure the "Priority Task" is visible.
    - **Visual:** Smoothly scroll down the home screen to show the "Insights" (Mood: 🔥, Energy: ⚡).
- **0:20 - [Zoom in on "Priority Task"]**
    - **Instruction:** Point or tap near the "Priority Task" card (e.g., "Investor Meeting").
    - **Visual:** Stay still for a few seconds to let the text sink in.

### Scene 2: Agentic Keyboard & Bio (0:30 - 1:00)
- **0:30 - [Close up of typing in WhatsApp/Notes]**
    - **Instruction:** Open WhatsApp or Notes. Switch to the **Typira Keyboard**.
    - **Input:** Type: *"The pitch deck is almost ready, but I'm worried about the Q3 projection."*
- **0:40 - [Transition to User Bio Screen]**
    - **Instruction:** Switch back to the Typira App and tap the **Bio** icon (or Profile).
    - **Visual:** Show fields like *"Working on a startup"*, *"Likely a night owl"*.
- **0:50 - [Screen shows a Suggestion]**
    - **Instruction:** While typing in Notes: *"Meeting with Mark at 2pm tomorrow"*.
    - **Visual:** Watch for the keyboard toolbar to suggest: *"Add to Calendar?"*. (Note: Trigger this by typing something relevant).

### Scene 3: Multimodal Interaction (1:00 - 1:30)
- **1:00 - [User taps Microphone]**
    - **Instruction:** Using the Typira keyboard toolbar, tap the **Mic** icon.
    - **Voice Input:** *"Remind me to buy groceries for the party tonight."*
- **1:20 - [User taps Camera via Keyboard]**
    - **Instruction:** Tap the **Camera** icon on the keyboard toolbar.
    - **Action:** Take a photo of a piece of paper (or use a mock image).
    - **Input:** Type: *"File this."*
- **1:25 - [App Screen]**
    - **Instruction:** Switch to Typira App -> **Memories**.
    - **Visual:** Highlight the new memory card: *"Filed electric bill from photo."*

### Scene 4: The "Brain" (1:30 - 2:00)
- **1:30 - [Transition to "The Matrix" view]**
    - **Instruction:** Show your Terminal running the Typira backend.
    - **Action:** Trigger an action (like the voice command above) and watch the Python logs scroll.
- **1:40 - [Highlight "Chain of Thought"]**
    - **Visual:** Point to the JSON output in the logs showing `thoughts: [...]`.

### Scene 5: Background Insights (2:00 - 2:30)
- **2:00 - [Screen shows "Scheduled Insight"]**
    - **Instruction:** On Typira Home Screen, find the **Insights** section.
    - **Visual:** Tap a card like *"Startup Funding News"* or *"Daily Productivity Recap"*.
- **2:10 - [Clicking the card]**
    - **Visual:** Show the expanded view with the AI summary.

---

## Pro-Tips for Recording
- **Slow & Steady:** Don't rush through taps. Give the viewer time to see what's happening.
- **Dark Mode:** Use Dark Mode for a "Premium" look.
- **Clear Terminal:** If showing the backend, use `clear` before triggering the logs for Scene 4.
