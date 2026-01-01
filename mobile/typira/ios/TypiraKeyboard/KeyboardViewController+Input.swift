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
             proxy.insertText(" ")
             isLastKeyWordBoundary = true
        case "⌫":
             proxy.deleteBackward()
             isLastKeyWordBoundary = false 
        case "return":
             proxy.insertText("\n")
             isLastKeyWordBoundary = true
        default:
            if title == "123" || title == "ABC" || title == "#+=" || title == "Shift" {
                break
            }
            
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
        // Trigger suggestion logic when text changes
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        if context.isEmpty {
            suggestionLabel?.text = "Start typing for AI suggestions..."
            return
        }
        
        suggestionTimer?.invalidate()
        
        // Smart Debounce
        let delay = isLastKeyWordBoundary ? 0.6 : 1.5
        
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.fetchAISuggestion(for: context)
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
