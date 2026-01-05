import Foundation
import UIKit
import SocketIO 

class TypingHistoryManager {
    
    private let baseUrl = "http://localhost:7009" 
    private var textBuffer = ""
    private var timer: Timer?
    private let debounceDelay: TimeInterval = 2.0
    
    var onThoughtUpdate: ((String) -> Void)?
    
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
                self?.onThoughtUpdate?("💡 \(thought)")
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
    
    private func syncHistory(proxy: UITextDocumentProxy) {
        guard !textBuffer.isEmpty else { return }
        
        // We use the buffer to know IF we should sync, but we send the FULL context for analysis
        let incrementalDelta = textBuffer
        textBuffer = ""
        
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        let fullText = before + after
        
        let payload: [String: Any] = [
            "token": jwtToken ?? "",
            "text": fullText,
            "incremental_delta": incrementalDelta,
            "is_full_context": true,
            "app_context": "ios.extension.keyboard"
        ]
        
        socket?.emit("analyze", payload)
        NSLog("DEBUG: [TypiraSocket] Synced Full Context (\(fullText.count) chars) to Backend")
    }

    func sendFullContext(_ fullText: String, proxy: UITextDocumentProxy) {
        if proxy.isSecureTextEntry == true {
            return
        }
        
        let payload: [String: Any] = [
            "token": jwtToken ?? "",
            "text": fullText,
            "is_full_context": true,
            "app_context": "ios.extension.keyboard"
        ]
        
        socket?.emit("analyze", payload)
        NSLog("DEBUG: [TypiraSocket] Emitting 'full_context' for \(fullText.count) chars")
    }
}
