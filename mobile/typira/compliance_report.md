# App Store Compliance Report

## ✅ 1. Full Access Justification
- **Status**: Compliance Met.
- **Evidence**:
    - `Info.plist` requests `RequestsOpenAccess` = `YES`.
    - **Justification Added**: `SetupActivity` now explicitly states: "This allows Typira to sync your typing context for personalized AI memory and manage your calendar."
    - `Privacy Policy` explicit section added: "User Content (Typing Data)" explanation.
- **Action Required**: Copy the explanation from `SetupActivity` to the **App Store Review Notes** when submitting.

## ✅ 2. Privacy Policy
- **Status**: Compliance Met.
- **Evidence**:
    - URL: `https://typira.celestineobi.com/legal/privacy`
    - Content: Explicitly mentions "Keyboard Extension", "Full Access", and "User Content (Typing Data)".
    - **Transparency**: Discloses that typing history *is* stored for personalization, but NOT sold or shared.


## ✅ 3. Secure Text Entry (Technical Gotcha)
- **Status**: ✅ Compliance Met (Double Layer Protection).
- **Layer 1 (OS)**: iOS automatically disables custom keyboards for fields marked `secureTextEntry` (passwords). This is the primary defense.
- **Layer 2 (Code)**: Added explicit code in `KeyboardViewController+AI.swift` AND `TypingHistoryManager.swift` to **disable all AI/Analysis network requests** if the keyboard type indicates sensitive data (Number Pad, Phone Pad, Decimal Pad, etc.).
- **Proof for Review**: `textDocumentProxy.keyboardType` is checked before REST requests and Socket emits.

## ✅ 4. Data Collection & Safety
- **Status**: Compliance Met.
- **Evidence**:
    - Network calls go to `https://typira.celestineobi.com/api/suggest`.
    - Payload: `text` (current buffer) and `context` (memory).
    - **Storage**: Data is stored to build "Memory".
    - **Transparency**: Privacy Policy discloses this storage.

## ✅ 5. Entitlements
- **Status**: Compliance Met.
- **Evidence**:
    - App Groups: `group.com.typira.appdata` configured in `TypiraKeyboard.entitlements` and `Runner.entitlements`.
    - Network: Implicitly allowed via standard URLSession.

## Next Steps for Submission
1.  **App Privacy Questionnaire**:
    *   **Data Collected?**: Yes.
    *   **User Content**: Yes (Text input).
    *   **Linked to User?**: Yes (Since you have accounts).
    *   **Used for Tracking?**: No.
    *   **Purpose**: "Product Personalization" (Memory) and "App Functionality" (Suggestions).
2.  **Review Notes**: Paste the following:
    > "This app includes a custom keyboard extension to provide AI writing assistance. The keyboard utilizes 'Full Access' to transmit text context to our secure server for AI processing and to access the user's calendar for scheduling events. User typing history is securely stored to build a personalized 'Memory' for context-aware suggestions, as disclosed in our Privacy Policy and Onboarding. The keyboard functionality is disabled for secure text entry fields by the iOS system."
