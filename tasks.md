# Typira Hackathon Sprint Plan (3 Weeks)

## Week 1: The Core Brain & UI (Context + Thoughts)
**Goal:** The Agent *understands* history and *thinks* visibly in the keyboard.

- [x] **UI "The Flip"**
    - [x] Android: Text Box (Middle), Action Grid (Bottom)
    - [x] iOS: Text Box (Middle), Action Grid (Bottom)
- [/] **Core Context System (The Brain)**
    - [ ] Backend: Verify `models/context.py` (TypingHistory) linked to User
    - [ ] Backend: Implement `POST /analyze` in `ai.py` with `@token_required`
    - [ ] Mobile: Send `jwt_token` & `typing_history` to `/analyze`
- [ ] **"Thought Stream" Integration**
    - [ ] Backend: `/analyze` returns "Thought Trace" + "Suggested Actions"
    - [ ] Android: Bind text box to live "Thought Trace" stream
    - [ ] iOS: Bind text box to live "Thought Trace" stream

## Week 2: The Ghost (Background & Notifications)
**Goal:** The Agent *works* while you sleep and notifies you when done.

- [ ] **Notification Infrastructure**
    - [ ] Backend: FCM/APNs Admin Setup
    - [ ] Android: Firebase Messaging Client
    - [ ] iOS: APNs / UserNotifications Client
- [ ] **"Marathon Loop" Logic**
    - [ ] Backend: Background worker to scan `typing_history` every few minutes
    - [ ] Backend: Trigger logic (e.g., "Found a meeting -> Draft Calendar Event")
    - [ ] Notification Payload: Send "Actionable Notification" (Title + Action Data)

## Week 3: The Bridge (Deep Links & Polish)
**Goal:** The Agent *handoffs* complex tasks to other apps reliably.

- [ ] **Intent URL Engine**
    - [ ] Backend: Generator for `mailto:`, `calshow:`, `sms:`, `https://wa.me/`
    - [ ] Backend: Support for specialized schemes (`spotify:`, `uber:`)
- [ ] **Action Execution UI**
    - [ ] Mobile: Handle "Action Chip" taps -> `Intent.ACTION_VIEW` / `openURL`
    - [ ] Mobile: "Deep Link Handoff" animation/feedback
- [ ] **Hackathon Polish**
    - [ ] Onboarding: "Enable Keyboard" Flow
    - [ ] Demo Mode: Pre-seeded history for Judges
