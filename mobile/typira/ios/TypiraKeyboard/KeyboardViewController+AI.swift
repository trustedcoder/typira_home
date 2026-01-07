import UIKit
import Foundation

extension KeyboardViewController {
    
    func fetchAISuggestion(for currentText: String) {
        DispatchQueue.main.async {
            self.suggestionLabel?.alpha = 0.5
        }
        
        // Smart Check: Min length
        if currentText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
             NSLog("DEBUG: [Swift] Skipping suggestion, context too short (<3 chars)")
             return
        }

        guard let url = URL(string: "http://localhost:8000/suggest") else { return }
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
        
        // Lookup Smart Metadata
        if let metadata = currentSmartActions.first(where: { ($0["id"] as? String) == actionId }) {
            let type = metadata["type"] as? String ?? ""
            let payload = metadata["payload"] as? String ?? ""
            
            NSLog("DEBUG: [Action] Tapped Smart Chip: \(actionId) Type: \(type)")
            
            if type == "deep_link" {
                if let url = URL(string: payload) {
                    // In Keyboard Extensions, we use extensionContext?.open
                    self.extensionContext?.open(url, completionHandler: nil)
                    self.suggestionLabel?.text = "Opening \(actionId)..."
                }
            } else if type == "prompt_trigger" {
                // Iterative AI Loop
                let before = textDocumentProxy.documentContextBeforeInput ?? ""
                let after = textDocumentProxy.documentContextAfterInput ?? ""
                let fullContext = before + after
                
                historyManager.performAction(id: actionId, type: type, payload: payload, context: fullContext)
                
                // Visual feedback: show specific action thought
                self.suggestionLabel?.text = "Typira is working on: \(title)..."
            }
            return
        }
        
        // Legacy/Fixed Action Strip Buttons
        if actionId == "rewrite" || title == "✨ Rewrite" {
            showView(.agent)
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
            showView(.agent)
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
             guard let url = URL(string: "http://localhost:8000/remember") else { return }
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
