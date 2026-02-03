// In KeyboardViewController+AI.swift

func fetchAISuggestion(for currentText: String) {
    // ...
    
    let proxy = self.textDocumentProxy
    
    // SAFETY CHECK: Disable AI for sensitive input types
    // We explicitly block API calls for Number pads, Phone pads, etc.
    let sensitiveTypes: [UIKeyboardType] = [
        .numberPad, 
        .phonePad, 
        .decimalPad, 
        .namePhonePad, 
        .emailAddress
    ]
    
    if sensitiveTypes.contains(proxy.keyboardType) {
        NSLog("DEBUG: [Security] AI disabled for sensitive keyboard type")
        return
    }

    // ... proceed with request
}

// In TypingHistoryManager.swift (Socket Analysis)

func onTextTyped(_ text: String, proxy: UITextDocumentProxy) {
     if sensitiveTypes.contains(proxy.keyboardType) {
          return // ABORT: Do not buffer or analyze
     }
     // ...
}
