# Typira Product Roadmap

## Vision
To build an intent-aware, emotionally intelligent, agentic assistant that lives where human decisions happen—the keyboard.

## Phase 1: Foundation & Core Presence (Category A, D)
**Goal:** Establish the app existence on user devices with a functional keyboard and basic backend connectivity, ensuring privacy and trust from day one.

### Mobile (Android & iOS)
- [ ] **Custom Keyboard Skeleton**: Build the base Input Method Service (Android) / Custom Keyboard Extension (iOS).
- [ ] **Basic Typing Support**: QWERTY layout, shift key, backspace, and basic punctuation.
- [ ] **Permission Management**: Implement transparent permission requesting flow (Category D).
- [ ] **Local Voice Input MVP**: Basic voice dictation using on-device speech-to-text APIs.

### Backend API
- [ ] **Project Setup**: Initialize scalable API framework (e.g., Node.js/Python).
- [ ] **Authentication**: Secure device/user authentication mechanisms.
- [ ] **Infrastructure**: CI/CD pipelines, staging environments.

## Phase 2: Local Understanding & Privacy Layer (Category B, E - Part 1)
**Goal:** Implement the "Privacy-First Intelligence" to understand user context locally before any cloud interaction.

### Mobile
- [ ] **Local Emotion Engine**: Implement algorithms to analyze typing speed, pauses, and backspaces to detect stress/urgency.
- [ ] **Intent Detection Engine**: Build local regex/logic to detect intents like "Remind me", "Let's meet".
- [ ] **Time & Entity Extraction**: Local NLP to extract dates and entities.
- [ ] **Preprocessing Layer**: Logic to strip sensitive data/PII before any potential external request.
- [ ] **Smart UI Framework**: Create the UI components for the keyboard recommendation strip (where suggestions will appear).

## Phase 3: The AI Brain & Smart Output (Category C, E - Part 2)
**Goal:** Connect the local understanding to the Gemini 3 Agent Layer to provide smart responses and rewrites.

### Backend
- [ ] **Gemini Integration**: Setup secure client for Gemini 3 API.
- [ ] **Agentic Prompt Architecture**: Implement the prompt engineering system for different contexts (Reply, Rewrite, Plan).
- [ ] **Smart Reply Endpoint**: API to receive safe context and return smart replies.
- [ ] **Rewrite Endpoint**: API to accept draft text and return tone-modified versions.

### Mobile
- [ ] **Action Loop UI**: Implement the "Suggest -> Review -> Approve" flow (Category D).
- [ ] **Smart Reply Feature**: Integration of Smart Reply API in the keyboard toolbar.
- [ ] **Rewrite Feature**: functionality to select text and request a rewrite.

## Phase 4: Agentic Productivity & Creative Mode (Category F, G)
**Goal:** Transform the keyboard into a productivity tool and creative assistant.

### Mobile
- [ ] **System Integrations**:
    - Android: Calendar provider, Reminder API.
    - iOS: EventKit, Reminder integration (handling permissions).
- [ ] **Goal Management UI**: Interface to capture and track goals detected from typing.
- [ ] **Content Creation UI**: "Creation Mode" toolbar for generating posts/captions.

### Backend
- [ ] **Scheduling Agent**: Logic to parse rough time inputs into concrete calendar events.
- [ ] **Goal Decomposition**: Agent logic to break down "I want to X" into steps.
- [ ] **Creative Agent**: Specialized prompts for social media usage (LinkedIn/Twitter formats).

## Phase 5: Memory, Proactivity & Polish (Category H, I, J)
**Goal:** Long-term memory, proactive suggestions, and platform specific polish.

### Mobile
- [ ] **Proactive Suggestions**: Logic to trigger suggestions based on local heuristics (Time of day, app open).
- [ ] **Platform Specifics**:
    - Android: Notification replies, Chat heads (if viable).
    - iOS: Widgets, App Intents (Shortcuts).
- [ ] **User Controls**: Full settings panel for Memory, Privacy opt-outs.

### Backend
- [ ] **Memory System**: Secure storage for user preferences and style (Voice/Tone).
- [ ] **Self-Correcting Logic**: Feedback loop API to update user preferences based on rejected/edited suggestions.
