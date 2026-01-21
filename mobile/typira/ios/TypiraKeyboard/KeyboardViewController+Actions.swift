import UIKit
import EventKit

extension KeyboardViewController {

    @objc func didTapActionChip(_ sender: UIButton) {
        guard let actionId = sender.accessibilityIdentifier else { return }
        
        // Find action data cache
        let action = self.currentSmartActions.first { ($0["id"] as? String) == actionId }
        
        if let action = action {
            handleNativeAction(action)
        } else if actionId == "hub" {
             // Open Main App
             openURL(url: URL(string: "typira://home")!)
        } else if actionId == "rewrite" {
             // Handled by tool logic elsewhere, or we can handle here
             historyManager.performAction(actionId, "tool", [:], "")
        } else if actionId == "paste" {
             if let content = UIPasteboard.general.string {
                 self.textDocumentProxy.insertText(content)
             }
        }
    }
    
    func handleNativeAction(_ action: [String: Any]) {
        guard let type = action["type"] as? String else { return }
        let label = action["label"] as? String ?? "Action"
        
        self.suggestionLabel?.text = "Executing \(label)..."
        
        if type == "calendar_event", let payload = action["payload"] as? [String: Any] {
            createCalendarEvent(payload)
        } else if type == "deep_link", let urlStr = action["payload"] as? String, let url = URL(string: urlStr) {
             openURL(url: url)
        } else if type == "prompt_trigger", let payload = action["payload"] as? String {
             // Send back to AI
             historyManager.performAction(action["id"] as! String, type, payload, "")
             self.suggestionLabel?.text = "Typira is working..."
        }
    }
    
    func createCalendarEvent(_ payload: [String: Any]) {
        let store = EKEventStore()
        
        store.requestAccess(to: .event) { [weak self] (granted, error) in
            guard granted else {
                DispatchQueue.main.async {
                    self?.suggestionLabel?.text = "🚫 Calendar Access Denied"
                }
                return
            }
            
            let event = EKEvent(eventStore: store)
            event.title = payload["title"] as? String ?? "New Event"
            event.notes = payload["description"] as? String
            
            if let startStr = payload["start"] as? String, let startDate = ISO8601DateFormatter().date(from: startStr) {
                event.startDate = startDate
            } else {
                event.startDate = Date()
            }
            
            if let endStr = payload["end"] as? String, let endDate = ISO8601DateFormatter().date(from: endStr) {
                event.endDate = endDate
            } else {
                event.endDate = event.startDate.addingTimeInterval(3600)
            }
            
            event.calendar = store.defaultCalendarForNewEvents
            
            do {
                try store.save(event, span: .thisEvent)
                DispatchQueue.main.async {
                    self?.suggestionLabel?.text = "✅ Event Created!"
                    // Optional: Insert text confirmation
                    // self?.textDocumentProxy.insertText("Scheduled \(event.title!) ")
                }
            } catch {
                DispatchQueue.main.async {
                    self?.suggestionLabel?.text = "❌ Failed to create event"
                }
            }
        }
    }
    
    // Workaround for opening URLs from Keyboard Extension
    func openURL(url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.perform(#selector(openURL(_:)), with: url)
                return
            }
            responder = responder?.next
        }
        
        // Fallback constraint: Extensions have hard time opening URLs directly without NSExtensionContext
        self.extensionContext?.open(url, completionHandler: nil)
    }
    
    @objc func didTapSuggestionLabel(_ sender: UITapGestureRecognizer) {
         if !lastSuggestedCompletion.isEmpty {
             self.textDocumentProxy.insertText(lastSuggestedCompletion)
             lastSuggestedCompletion = ""
             self.suggestionLabel?.text = "Typira is thinking..."
             self.suggestionLabel?.textColor = .gray
             self.suggestionLabel?.backgroundColor = .clear
         }
    }
}
