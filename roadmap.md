# Typira Product Roadmap: The Marathon Agent

## Vision
To build an autonomous, "Marathon Agent" leveraging Gemini 3 Pro that lives in the keyboard but works in the background. It observes user intent, thinks over hours/days, and proactively unblocks users via smart notifications and keyboard actions.

## Strategic Pivot: The "Action Era" Agent (Current Focus)
**Goal:** Shift from "Reactive Prediction" to "Proactive Orchestration".
*   **The Workflow:** User Intent -> Agent Thoughts (Multi-line Stream) -> Asynchronous Execution -> Notification/Action.

### Phase 1: The "Thought Stream" Interface (Immediate Priority)
- [ ] **UI Flipping**: Move Action Grid *below* the Suggestion Box.
- [ ] **Thought Stream**: Convert the Suggestion Box into a "Thinking Area" where the Agent explains its plan (e.g., "I see you agreed to a meeting. Checking your calendar...").
- [ ] **Smart Action Grid**: Dynamic list of tools (Calendar, Email, Maps) derived from the thought stream.

### Phase 2: The "Ghost" Agent (Background & Notifications)
- [ ] **Marathon Context Engine**:
    - [ ] **Typing History Ingestion**: Continuously store user typing (privacy-preserving) to build a long-term context window.
    - [ ] **User Persona Model**: Analyze history to understand user's role (e.g., "Product Manager"), tone, and frequent contacts.
- [ ] **Proactive Suggestions**: Use the "Marathon Context" to trigger actions *before* the user types (e.g., "It's 9am, draft standup?").
- [ ] **Push Notifications**: Agent sends "Task Ready" notifications (e.g., "Drafted that follow-up email") based on history and intent.
- [ ] **Notification Actions**: Interactive notifications that allow verifying/executing tools without opening the app.

### Phase 3: Deep Link & Action Handoff (The Bridge)
- [ ] **Intent URL Generation**: Smart construction of deep links (`mailto:`, `calshow:`) to bridge the App Gap.
- [ ] **Universal Links**: Support for specialized app schemas (Spotify, Uber) via user-defined templates.

## Deprioritized / Later
- [ ] Local Voice Input (Mic)
- [ ] Basic Rewrite/Paste Buttons (Replaced by Smart Actions)
- [ ] Chat Heads (Android)
- [ ] Complex Local Privacy Engines (Focus on Cloud Agent first for Hackathon)
