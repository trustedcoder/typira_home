# Typira Task Breakdown

## Category A: Core Input & Presence
### 1. Custom AI Keyboard (Mobile)
- [x] **Project Init**: Initialize iOS Keyboard Extension and Android InputMethodService.
- [ ] **Layout Engine**:
    - [x] Design and implement QWERTY Keys layout (XML/SwiftUI/Jetpack Compose).
    - [x] Implement Shift/Caps Lock logic.
    - [x] Implement Symbol/Numeric layer switching.
- [ ] **Input Handling**:
    - [x] Handle key presses and commit text to InputConnection/TextDocumentProxy.
    - [x] Implement deletion (Backspace) interactions.
    - [x] Implement Cursor movement control.
- [x] **AI Context Memory (Selective Ingestion)**:
    - [x] Implement "Feed to AI" action in keyboard UI.
    - [x] Handle clipboard access level permissions.
    - [x] Implement local or backend storage for user "memories".
    - [x] Integrate stored memories into Gemini prompt context (RAG).
- [x] **Emoji Board**:
    - [x] Implement Emoji parsing and display grid.
    - [x] Handle emoji selection and insertion.

### 2. AI Voice Input (Gemini-Powered)
- [x] **Mic Button**: Add Microphone icon to the keyboard toolbar.
- [x] **Streaming Audio**: Implement audio capturing and streaming from Native to Backend.
    - [x] **Android**: Hybrid bridge to Flutter.
    - [x] **iOS**: Native Swift implementation for memory safety.
- [x] **Gemini STT**: Integrate Gemini API on the backend to transcribe audio.
- [x] **Auto-Insert**: Automatically insert transcribed text into the current field.

### 3. AI Read-Aloud (Gemini TTS)
- [x] **🔊 Listen Action**: Add a listen button next to AI suggestions.
- [x] **Gemini TTS**: Use Gemini/Cloud TTS to generate audio for suggestions.
- [x] **Audio Playback**: Implement high-quality playback on the mobile device. (Native TTS fallback used for reliability)

## Category B: Local Understanding (Privacy-First)
### 3. Local Emotion Signal Engine (Mobile)
- [ ] **Data Collection**: Hook into keyboard input stream to measure keystroke dynamics (dwell time, flight time).
- [ ] **Analysis Logic**:
    - [ ] Calculate words-per-minute rolling average.
    - [ ] Detect rapid backspacing (frustration signal).
    - [ ] Detect punctuation intensity (!!! vs .).
- [ ] **Vector Output**: Map signals to abstract local state (e.g., `UrgencyLevel: High`).

### 4. Local Intent Detection (Mobile)
- [ ] **Regex Engine**: Implement lightweight pattern matcher for common phrases.
- [ ] **Intent Mapping**:
    - [ ] Map "Remind me" -> `INTENT_REMINDER`.
    - [ ] Map "Let's meet" -> `INTENT_SCHEDULING`.
    - [ ] Map "I want to" -> `INTENT_GOAL`.

### 5. On-Device Preprocessing (Mobile)
- [ ] **PII Stripper**: Regex to remove emails/phones before sending to AI (if needed).
- [ ] **Context Compressor**: Summarize last N messages for the Prompt context.

## Category C: AI Brain (Backend & Integration)
### 7. Gemini 3 Agent Layer (Backend)
- [ ] **Gemini Client**:
    - [ ] Implement Google AI Studio / Vertex AI client connection.
    - [ ] internal API wrapper for Typira.
- [ ] **Prompt Manager**:
    - [ ] Create template engine for System Prompts.
    - [ ] Version control prompts for "Rewrite", "Reply", "Plan".

### 8. Agent Integration (Mobile)
- [ ] **Networking**: Secure Retrofit/Alamofire client to Typira Backend.
- [ ] **Request Formatting**: Bundle `InputText`, `LocalSignals`, and `Intent` into JSON payload.
- [ ] **Streaming**: Handle streaming responses for faster UI perception.

## Category D: User Control & Trust
### 9. Approval Loop (Mobile)
- [ ] **Suggestion UI**:
    - [ ] Floating bar or "Smart Strip" above keyboard.
    - [ ] "Accept" (One tap), "Edit" (Long press/Tap), "Reject" (Swipe away) interactions.
- [ ] **Safety Checks**: Ensure no API call is made without user trigger (or explicit opt-in).

### 10. Settings & Permissions (Mobile)
- [ ] **Privacy Dashboard**: Screen showing what data is processed and where.
- [ ] **Toggles**: Logic to completely disable specific features (e.g., "Disable Emotion Analysis").

## Category E: Smart Output
### 12. Smart Replies (Mobile + Backend)
- [ ] **Backend**: Create `/generate-reply` endpoint.
- [ ] **Mobile**: Capture screen text (Accessibility Service on Android, or just current field on iOS?). 
    - *Note: iOS limits reading other app context. Focus on 'Response to copied text' or 'Conversation mode' if possible.*

### 13. Rewrite & Tone (Mobile + Backend)
- [ ] **UI**: "Magic Wand" button in toolbar.
- [ ] **Selection**: Handle text selection limits.
- [ ] **Backend**: `/rewrite` endpoint taking `text` + `target_tone`.

## Category F: Creative
### 14. Content Creation (Mobile)
- [ ] **Toolbar Mode**: Switch keyboard view to "Creator" palette.
- [ ] **Platform Selectors**: Icons for Twitter/LinkedIn/etc. to prompt Backend correctly.

## Category G: Agentic Productivity
### 16. Scheduling (Mobile)
- [ ] **Parsing**: Client-side extraction of specific date/times from intent.
- [ ] **Calendar API**:
    - [ ] Android `CalendarContract` insert intent.
    - [ ] iOS `EKEventStore` interaction.

### 18. Goal Detection (Backend)
- [ ] **Goal API**: `/analyze-goal` endpoint.
- [ ] **Decomposition**: Gemini prompt to split "Learn Spanish" into "Download App", "Practice Daily".

## Category I: Memory (Backend)
### 21. Memory System
- [ ] **Database**: User-specific encrypted storage (e.g., PostgreSQL + Encryption).
- [ ] **Preference API**: Endpoints to GET/UPDATE `UserStyle`.
## Category J: Reorganized UI & Agent Hub
### 22. Agent Hub (Mobile)
- [ ] **Grid Navigation**:
    - [ ] Implement Categorized Grid Layout for Agent Actions (Generation, Productivity, Insights).
    - [ ] Integrate categorized buttons (Social Content, Article Writing, Habit Tracking, etc.).
- [ ] **Contextual Agentic UI**:
    - [ ] Implement "Voice View" overlay with real-time pulse animation.
    - [ ] Implement "Smart Bubbles/Toasts" for high-priority contextual suggestions.
- [ ] **Deep Linking**:
    - [ ] Implement bridge to open the main Typira app for complex agentic flows.

### 23. Contextual Engine (Backend)
- [ ] **Intent Classifier**:
    - [ ] Add `/analyze-intent` endpoint for real-time typing history analysis.
    - [ ] Update STT and Rewrite endpoints to return `suggested_action` metadata.
- [ ] **Notification Bridge**:
    - [ ] Implement logic to trigger System Notifications for non-keyboard agentic tasks.
