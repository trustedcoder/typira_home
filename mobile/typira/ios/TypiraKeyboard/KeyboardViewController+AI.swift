import UIKit
import Foundation
import EventKit

extension KeyboardViewController {
    
    func fetchAISuggestion(for currentText: String) {
        NSLog("DEBUG: [AI] Requesting suggestion for: \(currentText)")
        DispatchQueue.main.async {
            self.suggestionLabel?.alpha = 0.5
        }
        
        // Smart Check: Min length
        if currentText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
             NSLog("DEBUG: [Swift] Skipping suggestion, context too short (<3 chars)")
             return
        }

        guard let url = URL(string: "https://typira.celestineobi.com/api/suggest") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let prefs = UserDefaults.standard
        let memories = prefs.stringArray(forKey: "typira_memories") ?? []
        let context = memories.joined(separator: ". ")
        
        let bodyParameters = [
            "text": currentText,
            "context": context
        ]
        
        let bodyString = bodyParameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        self.lastTypedLength = currentText.count
        
        // Cancellation
        currentTask?.cancel()
        
        currentTask = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.suggestionLabel?.alpha = 1.0
                
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorCancelled {
                        return
                    }
                    
                    self.suggestionLabel?.text = "..."
                    return
                }
                
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let suggestion = json["suggestion"] as? String {
                    if suggestion.isEmpty {
                        self.lastSuggestedCompletion = ""
                        self.suggestionLabel?.text = "..."
                    } else {
                        self.lastSuggestedCompletion = suggestion
                        self.suggestionLabel?.text = "\(suggestion) (Tap to insert)"
                    }
                }
            }
        }
        currentTask?.resume()
    }
    
    @objc func didTapActionChip(_ sender: UIButton) {
        let title = sender.title(for: .normal) ?? ""
        let actionId = sender.accessibilityIdentifier ?? ""
        NSLog("DEBUG: [Action] Tapped Action Chip: id=\(actionId) tag=\(sender.tag) title=\(title)")
        
        // Lookup Smart Metadata
        if let metadata = currentSmartActions.first(where: { ($0["id"] as? String) == actionId }) {
            let type = metadata["type"] as? String ?? ""
            let rawPayload = metadata["payload"]
            
            NSLog("DEBUG: [Action] Tapped Smart Chip: \(actionId) Type: \(type)")
            
            if type == "deep_link" {
                if let payload = rawPayload as? String, let url = URL(string: payload) {
                    openApp(url: url)
                    self.suggestionLabel?.text = "Opening \(actionId)..."
                }
            } else if type == "calendar_event" {
                if let payload = rawPayload as? [String: Any] {
                    handleNativeCalendarEvent(payload: payload, label: title)
                }
            } else if type == "prompt_trigger" {
                // Iterative AI Loop
                let payload = rawPayload as? String ?? ""
                let before = textDocumentProxy.documentContextBeforeInput ?? ""
                let after = textDocumentProxy.documentContextAfterInput ?? ""
                let fullContext = before + after
                
                historyManager.performAction(id: actionId, type: type, payload: payload, context: fullContext)
                
                // Visual feedback: show specific action thought
                self.suggestionLabel?.text = "Typira is working on: \(title)..."
            }
            return
        }
 else {
            NSLog("DEBUG: [Action] Metadata lookup FAILED for actionId: '\(actionId)'. Current actions: \(currentSmartActions.count)")
        }
        
        // Legacy/Fixed Action Strip Buttons
        if actionId == "rewrite" || title == "✨ Rewrite" {
            if let url = URL(string: "typira://home") {
                openApp(url: url)
            }
        } else if actionId == "paste" || title == "🧠 Paste" {
            handleRememberAction()
            // Visual feedback
            let isIcon = sender.image(for: .normal) != nil
            let originalColor = !isIcon ? sender.backgroundColor : sender.tintColor
            if !isIcon {
                sender.backgroundColor = .cyan
                UIView.animate(withDuration: 1.0) { sender.backgroundColor = originalColor }
            } else {
                sender.tintColor = .cyan
                UIView.animate(withDuration: 1.0) { sender.tintColor = originalColor }
            }
        } else if actionId == "mic" || title == "🎙️" {
            handleMicAction()
        } else if actionId == "hub" {
            if let url = URL(string: "typira://home") {
                openApp(url: url)
            }
        }
    }
    
    private func openApp(url: URL) {
        NSLog("DEBUG: [Action] Attempting to open URL: \(url.absoluteString)")
        
        // 1. Try URLSession/NSExtensionContext standard way (Preferred)
        self.extensionContext?.open(url, completionHandler: { success in
            if success {
                NSLog("DEBUG: [Action] Successfully opened URL via extensionContext")
            } else {
                NSLog("DEBUG: [Action] Failed to open URL via extensionContext, trying responder chain...")
                
                // 2. Responder Chain Hack (Legacy Fallback)
                DispatchQueue.main.async {
                    var responder: UIResponder? = self
                    let selector = NSSelectorFromString("openURL:")
                    while responder != nil {
                        if responder!.responds(to: selector) {
                            responder!.perform(selector, with: url)
                            NSLog("DEBUG: [Action] Triggered openURL: on responder chain")
                            return
                        }
                        responder = responder!.next
                    }
                    NSLog("DEBUG: [Action] CRITICAL: No responder found for openURL:")
                }
            }
        })
    }
    
    private func handleNativeCalendarEvent(payload: [String: Any], label: String) {
        let eventStore = EKEventStore()
        
        func createEvent() {
            let event = EKEvent(eventStore: eventStore)
            event.title = payload["title"] as? String ?? "Reminder"
            event.notes = payload["description"] as? String ?? ""
            
            let dateFormatter = ISO8601DateFormatter()
            if let startStr = payload["start"] as? String, let startDate = dateFormatter.date(from: startStr) {
                event.startDate = startDate
            } else {
                event.startDate = Date()
            }
            
            if let endStr = payload["end"] as? String, let endDate = dateFormatter.date(from: endStr) {
                event.endDate = endDate
            } else {
                event.endDate = event.startDate.addingTimeInterval(3600) // 1 hour default
            }
            
            event.calendar = eventStore.defaultCalendarForNewEvents
            
            do {
                try eventStore.save(event, span: .thisEvent)
                DispatchQueue.main.async {
                    self.suggestionLabel?.text = "✅ Event Created: \(event.title!)"
                }
            } catch {
                NSLog("ERROR: [Calendar] Could not save event: \(error)")
                DispatchQueue.main.async {
                    self.suggestionLabel?.text = "❌ Failed to create event"
                }
            }
        }

        // Handle permissions
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                if granted {
                    createEvent()
                } else {
                    NSLog("ERROR: [Calendar] Full access denied: \(error?.localizedDescription ?? "unknown")")
                    DispatchQueue.main.async {
                        self.suggestionLabel?.text = "⚠️ Calendar permission required"
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                if granted {
                    createEvent()
                } else {
                    NSLog("ERROR: [Calendar] Access denied: \(error?.localizedDescription ?? "unknown")")
                    DispatchQueue.main.async {
                        self.suggestionLabel?.text = "⚠️ Calendar permission required"
                    }
                }
            }
        }
    }
    
    @objc func didTapSuggestionLabel(_ gesture: UITapGestureRecognizer) {
        if !lastSuggestedCompletion.isEmpty {
            if lastTypedLength > 0 {
                for _ in 0..<lastTypedLength {
                    textDocumentProxy.deleteBackward()
                }
            }
            textDocumentProxy.insertText(lastSuggestedCompletion + " ")
            lastSuggestedCompletion = ""
            lastTypedLength = 0
            suggestionLabel?.text = "..."
        }
    }
    
    func handleRememberAction() {
        if let text = UIPasteboard.general.string {
             if text.count < 3 { return }
             
             // Save locally
             let prefs = UserDefaults.standard
             var memories = prefs.stringArray(forKey: "typira_memories") ?? []
             memories.append(text)
             prefs.set(memories, forKey: "typira_memories")
             
             // Sync backend
             guard let url = URL(string: "https://typira.celestineobi.com/remember") else { return }
             var request = URLRequest(url: url)
             request.httpMethod = "POST"
             request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
             let body = "text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
             request.httpBody = body.data(using: .utf8)
             
             URLSession.shared.dataTask(with: request).resume()
        }
    }
    
    func handleRewriteAction() {
         // This needs context from document.
         // Since textDocumentProxy access is limited, we rely on what we can get manually or user selection logic if specific.
         // For now, assume we rewrite the last typed sentence or similar?
         // Actually, Typira Design often uses "Rewrite" in Agent Hub.
         // We'll leave the implementation stub here calling the agent logic
    }
    
    func requestNativeRewrite(_ text: String) {
        // Implementation similar to suggestion but hitting /rewrite
        // ... (Simplified for brevity, or add if needed)
    }
}
