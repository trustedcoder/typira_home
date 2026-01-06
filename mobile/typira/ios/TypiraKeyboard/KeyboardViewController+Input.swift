import UIKit

extension KeyboardViewController {
    
    @objc func didTapKey(_ sender: UIButton) {
        let title = sender.title(for: .normal) ?? ""
        let proxy = self.textDocumentProxy
        
        if sender.tag == 101 { // Shift
             handleShiftTap()
             return
        }
        
        if sender.tag == 102 { // Mode (123)
            toggleSymbols()
            return
        }

        if sender.tag == 103 { // Emoji Tag
            toggleEmojiView()
            return
        }
        
        switch title {
        case "space":
             historyManager.onTextTyped(" ", proxy: proxy)
             proxy.insertText(" ")
             isLastKeyWordBoundary = true
        case "⌫":
             // Optional: handle backspace in buffer? 
             // For now, we skip backspace in ingestion to avoid 'corruption' 
             // or we could implement a smarter buffer. 
             // Let's just pass it and let the buffer handle it if we want.
             proxy.deleteBackward()
             isLastKeyWordBoundary = false 
        case "return":
             historyManager.onTextTyped("\n", proxy: proxy)
             proxy.insertText("\n")
             isLastKeyWordBoundary = true
        default:
            if title == "123" || title == "ABC" || title == "#+=" || title == "Shift" {
                break
            }
            
            // Feed to History Manager
            historyManager.onTextTyped(title, proxy: proxy)
            
            proxy.insertText(title)
            
            if symbolChars.contains(title) || extraSymbolChars.contains(title) {
                isLastKeyWordBoundary = true
            } else {
                isLastKeyWordBoundary = false
            }
            
            if !isSymbols && shiftState == .on {
                 shiftState = .off
                 updateShiftUI()
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            NSLog("DEBUG: Key tapped ('\(title)'), manually triggering suggestion check")
            self?.textDidChange(nil)
        }
    }
    
    // Core selection / cursor logic could go here if exposed
    
    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        let fullContent = before + after
        
        // Dynamic Full Context Ingestion
        // Check if length changed (grew OR shrank - revealing/deleting) or content shifted
        if !fullContent.isEmpty && (fullContent.count != lastSyncedContext.count || !fullContent.contains(lastSyncedContext)) {
            
            let capturedAtTrigger = fullContent
            let oldSyncLen = lastSyncedContext.count
            lastSyncedContext = capturedAtTrigger // Anticipatory update
            
            NSLog("DEBUG: [iOSContext] Potential context reveal (Old: \(oldSyncLen), Current: \(capturedAtTrigger.count)). Checking in 0.6s...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self = self else { return }
                let finalBefore = self.textDocumentProxy.documentContextBeforeInput ?? ""
                let finalAfter = self.textDocumentProxy.documentContextAfterInput ?? ""
                let finalFull = finalBefore + finalAfter
                
                // If the system revealed more or different text than we last synced
                if finalFull != self.lastSyncedContext {
                    NSLog("DEBUG: [iOSContext] SYNCING: Found \(finalFull.count) total chars (Before: \(finalBefore.count), After: \(finalAfter.count))")
                    self.historyManager.sendFullContext(finalFull, proxy: self.textDocumentProxy)
                    self.lastSyncedContext = finalFull
                }
            }
        }

        // Trigger suggestion logic when text changes
        if before.isEmpty {
            suggestionLabel?.text = "Start typing for AI suggestions..."
            return
        }
        
        suggestionTimer?.invalidate()
        
        // Smart Debounce
        let delay = isLastKeyWordBoundary ? 0.6 : 1.5
        
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.fetchAISuggestion(for: before)
        }
    }

    func toggleSymbols() {
        if isEmojiView { toggleEmojiView() }
        isSymbols = !isSymbols
        isMoreSymbols = false
        
        if isSymbols {
            modeButton?.setTitle("ABC", for: .normal)
            shiftButton?.setTitle("#+=", for: .normal)
        } else {
            modeButton?.setTitle("123", for: .normal)
            updateShiftUI()
        }
        updateKeys()
    }
    
    func handleShiftTap() {
        if isEmojiView { toggleEmojiView() }
        if isSymbols {
             isMoreSymbols = !isMoreSymbols
             if isMoreSymbols {
                  shiftButton?.setTitle("123", for: .normal)
             } else {
                  shiftButton?.setTitle("#+=", for: .normal)
             }
             updateKeys()
             return
        }
    
        let now = Date().timeIntervalSince1970
        if shiftState == .off {
            if now - lastShiftPressTime < doubleTapTimeout {
                shiftState = .locked
            } else {
                shiftState = .on
            }
        } else if shiftState == .on {
            if now - lastShiftPressTime < doubleTapTimeout {
                shiftState = .locked
            } else {
                shiftState = .off
            }
        } else {
            shiftState = .off
        }
        lastShiftPressTime = now
        updateShiftUI()
    }
    
    @objc func handleSpacePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        let threshold: CGFloat = 10.0
        
        if abs(translation.x) > threshold {
            let offset = translation.x > 0 ? 1 : -1
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
            gesture.setTranslation(.zero, in: self.view)
        }
    }

    func updateShiftUI() {
        if isSymbols { return }
        
        switch shiftState {
        case .off:
            shiftButton?.setTitle("⇧", for: .normal)
            shiftButton?.backgroundColor = UIColor(white: 0.65, alpha: 1.0)
            shiftButton?.setTitleColor(.black, for: .normal)
        case .on:
            shiftButton?.setTitle("⇧", for: .normal)
            shiftButton?.backgroundColor = .white
            shiftButton?.setTitleColor(.black, for: .normal)
        case .locked:
             shiftButton?.setTitle("⇪", for: .normal)
             shiftButton?.backgroundColor = .white
             shiftButton?.setTitleColor(.black, for: .normal)
        }
        updateKeys() // Ensure keys are updated with case
    }
    
    func updateKeys() {
        let qwertyArray = Array(qwertyChars)
        let symbolArray = Array(symbolChars)
        var extraString = extraSymbolChars
        while extraString.count < 26 { extraString += " " }
        let extraArray = Array(extraString)
        
        for (index, btn) in letterButtons.enumerated() {
            if isSymbols {
                if isMoreSymbols {
                     let char = index < extraArray.count ? extraArray[index] : " "
                     btn.setTitle(String(char), for: .normal)
                } else {
                     let char = index < symbolArray.count ? symbolArray[index] : " "
                     btn.setTitle(String(char), for: .normal)
                }
            } else {
                let char = index < qwertyArray.count ? qwertyArray[index] : " "
                if shiftState != .off {
                    btn.setTitle(String(char).uppercased(), for: .normal)
                } else {
                    btn.setTitle(String(char), for: .normal)
                }
            }
        }
    }
}
