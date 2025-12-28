# Typira Task Breakdown

## Category A: Core Input & Presence
### 1. Custom AI Keyboard (Mobile)
- [x] **Project Init**: Initialize iOS Keyboard Extension and Android InputMethodService.
- [ ] **Layout Engine**:
    - [x] Design and implement QWERTY Keys layout (XML/SwiftUI/Jetpack Compose).
    - [x] Implement Shift/Caps Lock logic.
    - [x] Implement Symbol/Numeric layer switching.
- [ ] **Input Handling**:
    - [ ] Handle key presses and commit text to InputConnection/TextDocumentProxy.
    - [ ] Implement deletion (Backspace) interactions.
    - [ ] Implement Cursor movement control.
- [ ] **Clipboard Integration**:
    - [ ] Add clipboard read permission handling.
    - [ ] Create UI for clipboard history (if allowed).
- [ ] **Emoji Board**:
    - [ ] Implement Emoji parsing and display grid.
    - [ ] Handle emoji selection and insertion.

### 2. Voice Input (Mobile)
- [ ] **Permissions**: Request Microphone access properly.
- [ ] **Dictation UI**: Create a wave/visualizer overlay/state.
- [ ] **Speech-to-Text**:
    - [ ] Integrate Android SpeechRecognizer.
    - [ ] Integrate iOS SFSpeechRecognizer.
- [ ] **Command Mode**: Implement keywords detection (locally) for "Remind me" vs raw value.

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
