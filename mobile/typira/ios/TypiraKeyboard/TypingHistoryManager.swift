import Foundation
import UIKit
import SocketIO 

class TypingHistoryManager {
    
    private let baseUrl = "http://localhost:7009" 
    private var textBuffer = ""
    private var timer: Timer?
    private let debounceDelay: TimeInterval = 2.0
    
    var onThoughtUpdate: ((String) -> Void)?
    var onActionsReceived: (([[String: Any]]) -> Void)?
    var onResultReceived: ((String) -> Void)?
    
    // App Group for sharing JWT token with Flutter app
    private let appGroupSuiteName: String? = nil 
    
    private var jwtToken: String? {
        let prefs = appGroupSuiteName != nil ? UserDefaults(suiteName: appGroupSuiteName) : UserDefaults.standard
        if let token = prefs?.string(forKey: "flutter.auth") {
             return token.replacingOccurrences(of: "\"", with: "")
        }
        return nil
    }
    
    private let manager = SocketManager(socketURL: URL(string: "http://localhost:7009")!, config: [.log(false), .compress])
    private var socket: SocketIOClient?
 
    init() {
        setupSocket()
    }
    
    private func setupSocket() {
        socket = manager.defaultSocket
        
        socket?.on(clientEvent: .connect) { data, ack in
            NSLog("DEBUG: [TypiraSocket] Connected to Backend")
        }
        
        socket?.on("thought_update") { [weak self] data, ack in
            if let dict = data[0] as? [String: Any], let text = dict["text"] as? String {
                self?.onThoughtUpdate?("💭 \(text)")
            }
        }
        
        socket?.on("suggestion_ready") { [weak self] data, ack in
            if let dict = data[0] as? [String: Any], let thought = dict["thought"] as? String {
                let actions = dict["actions"] as? [[String: Any]] ?? []
                let result = dict["result"] as? String ?? ""
                
                self?.onThoughtUpdate?("💡 \(thought)")
                self?.onActionsReceived?(actions)
                
                if !result.isEmpty {
                    self?.onResultReceived?(result)
                }
            }
        }
        
        socket?.on(clientEvent: .error) { data, ack in
            NSLog("DEBUG: [TypiraSocket] Error: \(data)")
        }
        
        socket?.connect()
    }
    
    func onTextTyped(_ text: String, proxy: UITextDocumentProxy) {
        if proxy.isSecureTextEntry == true {
            return
        }
        
        textBuffer += text
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { [weak self] _ in
            self?.syncHistory(proxy: proxy)
        }
    }
    
    private func scrubPII(_ text: String) -> String {
        var scrubbed = text
        
        // Redact Email
        let emailPattern = "[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+"
        scrubbed = applyRegex(pattern: emailPattern, replacement: "[EMAIL]", to: scrubbed)
        
        // Redact Credit Card
        let ccPattern = "\\b(?:\\d[ -]*?){13,16}\\b"
        scrubbed = applyRegex(pattern: ccPattern, replacement: "[CREDIT_CARD]", to: scrubbed)
        
        // Redact PIN (4-6 digits)
        let pinPattern = "\\b\\d{4,6}\\b"
        scrubbed = applyRegex(pattern: pinPattern, replacement: "[SENSITIVE_CODE]", to: scrubbed)
        
        return scrubbed
    }
    
    private func applyRegex(pattern: String, replacement: String, to text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: replacement)
    }

    private func syncHistory(proxy: UITextDocumentProxy) {
        guard !textBuffer.isEmpty else { return }
        
        let incrementalDelta = textBuffer
        textBuffer = ""
        
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        let fullText = before + after
        
        // Client-side PII scrubbing
        let cleanFullText = scrubPII(fullText)
        let cleanDelta = scrubPII(incrementalDelta)
        
        let payload: [String: Any] = [
            "token": jwtToken ?? "",
            "text": cleanFullText,
            "incremental_delta": cleanDelta,
            "is_full_context": true,
            "app_context": "ios.extension.keyboard"
        ]
        
        socket?.emit("analyze", payload)
        NSLog("DEBUG: [TypiraSocket] Synced Scrubbed Context (\(cleanFullText.count) chars) to Backend")
    }

    func sendFullContext(_ fullText: String, proxy: UITextDocumentProxy) {
        if proxy.isSecureTextEntry == true {
            return
        }
        
        let cleanFullText = scrubPII(fullText)
        
        let payload: [String: Any] = [
            "token": jwtToken ?? "",
            "text": cleanFullText,
            "is_full_context": true,
            "app_context": "ios.extension.keyboard"
        ]
        
        socket?.emit("analyze", payload)
        NSLog("DEBUG: [TypiraSocket] Emitting scrubbed 'full_context' for \(cleanFullText.count) chars")
    }
    
    func performAction(id: String, type: String, payload: String?, context: String) {
        let eventPayload: [String: Any] = [
            "token": jwtToken ?? "",
            "action_id": id,
            "type": type,
            "payload": payload ?? "",
            "context": context
        ]
        
        socket?.emit("perform_action", eventPayload)
        NSLog("DEBUG: [TypiraSocket] Emitting 'perform_action': \(id)")
    }
}
