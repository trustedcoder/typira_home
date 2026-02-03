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
        
        if sender.tag == 104 { // Next Keyboard (Globe)
            self.advanceToNextInputMode()
            return
        }
        
        if sender.tag == 105 { // Emoji Delete
            proxy.deleteBackward()
            isLastKeyWordBoundary = false
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
            shiftButton?.setImage(nil, for: .normal)
            shiftButton?.backgroundColor = KeyboardViewController.standardSpecialKeyColor
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
             shiftButton?.setTitle(isMoreSymbols ? "123" : "#+=", for: .normal)
             shiftButton?.setImage(nil, for: .normal)
             updateKeys()
             return
        }
    
        let now = Date().timeIntervalSince1970
        let isDoubleTap = (now - lastShiftPressTime < doubleTapTimeout)

        if isDoubleTap && shiftState == .on {
            shiftState = .locked
        } else if shiftState == .locked {
            shiftState = .off
        } else if shiftState == .on {
            shiftState = .off
        } else {
            shiftState = .on
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
        
        guard let btn = shiftButton else { return }
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        
        switch shiftState {
        case .off:
            if #available(iOS 13.0, *) {
                btn.setImage(UIImage(systemName: "shift", withConfiguration: config), for: .normal)
                btn.setTitle("", for: .normal)
            } else {
                btn.setTitle("⇧", for: .normal)
            }
            btn.backgroundColor = KeyboardViewController.standardSpecialKeyColor
            btn.tintColor = .black
        case .on:
            if #available(iOS 13.0, *) {
                btn.setImage(UIImage(systemName: "shift.fill", withConfiguration: config), for: .normal)
                btn.setTitle("", for: .normal)
            } else {
                btn.setTitle("⇧", for: .normal)
            }
            btn.backgroundColor = KeyboardViewController.standardCharKeyColor
            btn.tintColor = .black
        case .locked:
            if #available(iOS 13.0, *) {
                btn.setImage(UIImage(systemName: "capslock.fill", withConfiguration: config), for: .normal)
                btn.setTitle("", for: .normal)
            } else {
                btn.setTitle("⇪", for: .normal)
            }
            btn.backgroundColor = KeyboardViewController.standardCharKeyColor
            btn.tintColor = .black
        }
        updateKeys() // Ensure keys are updated with case
    }
    
    func updateKeys() {
        let qwertyArray = Array(qwertyChars)
        let symbolArray = Array(symbolChars)
        let extraArray = Array(extraSymbolChars)
        
        let rows = qwertyRowsStack?.arrangedSubviews as? [UIStackView] ?? []
        let row2 = rows.count > 1 ? rows[1] : nil

        for (index, btn) in letterButtons.enumerated() {
            if isSymbols {
                let char = isMoreSymbols ? (index < extraArray.count ? extraArray[index] : " ") : (index < symbolArray.count ? symbolArray[index] : " ")
                btn.setTitle(String(char), for: .normal)
                
                // --- Row 2 (index 10-19) ---
                if index == 19 {
                    btn.isHidden = false
                    row2?.layoutMargins = .zero
                    row2?.isLayoutMarginsRelativeArrangement = false
                }

                // --- Row 3 (index 20-26) ---
                if index >= 20 && index <= 26 {
                    btn.isHidden = (index > 24)
                }
            } else {
                let char = index < qwertyArray.count ? qwertyArray[index] : " "
                if shiftState != .off {
                    btn.setTitle(String(char).uppercased(), for: .normal)
                } else {
                    btn.setTitle(String(char), for: .normal)
                }

                // --- Row 2 (index 10-19) ---
                if index == 19 {
                    btn.isHidden = true
                    row2?.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
                    row2?.isLayoutMarginsRelativeArrangement = true
                }

                // --- Row 3 (index 20-26) ---
                if index >= 20 && index <= 26 {
                    btn.isHidden = false
                }
            }
        }
    }
}
