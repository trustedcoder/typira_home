//
//  KeyboardViewController.swift
//  TypiraKeyboard
//
//  Created by Typira Agent on 2025.
//

import UIKit

class KeyboardViewController: UIInputViewController {
    
    enum ShiftState {
        case off
        case on
        case locked
    }

    @IBOutlet var nextKeyboardButton: UIButton!
    
    // State
    var shiftState: ShiftState = .off
    var isSymbols = false
    var isMoreSymbols = false
    
    var lastShiftPressTime: Double = 0
    let doubleTapTimeout: Double = 0.3
    
    // Key Lists
    var letterButtons = [UIButton]()
    let qwertyChars = "qwertyuiopasdfghjklzxcvbnm"
    // iOS Standard 123 Layout (Mapped to 26 keys)
    // Row 1: 1 2 3 4 5 6 7 8 9 0
    // Row 2: - / : ; ( ) $ & @ "
    // Row 3: . , ? ! ' (Only 5 keys standard, filled last 2 with duplicate/space)
    let symbolChars = "1234567890-/:;()$&@\".,?!'  " 
    
    // iOS Standard #+= Layout
    // Row 1: [ ] { } # % ^ * + =
    // Row 2: _ \ | ~ < > € £ ¥ •
    // Row 3: . , ? ! ' 
    let extraSymbolChars = "[]{}#%^*+=_\\|~<>€£¥•.,?!'  "
    
    var shiftButton: UIButton?
    var modeButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardLayout()
    }
    
    func setupKeyboardLayout() {
        letterButtons.removeAll()
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.view.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
        
        let suggestionStrip = UIStackView()
        suggestionStrip.axis = .horizontal
        suggestionStrip.distribution = .fillProportionally
        suggestionStrip.spacing = 10
        suggestionStrip.translatesAutoresizingMaskIntoConstraints = false
        suggestionStrip.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        suggestionStrip.isLayoutMarginsRelativeArrangement = true
        
        for title in ["✨ Rewrite", "📅 Plan", "Reply"] {
            let btn = createChip(title: title)
            suggestionStrip.addArrangedSubview(btn)
        }
        self.view.addSubview(suggestionStrip)
        
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fillEqually
        mainStack.spacing = 10 
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mainStack)
        
        let safe = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            suggestionStrip.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 4),
            suggestionStrip.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            suggestionStrip.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            suggestionStrip.heightAnchor.constraint(equalToConstant: 44),
            
            mainStack.topAnchor.constraint(equalTo: suggestionStrip.bottomAnchor, constant: 4),
            mainStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -4),
            mainStack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -4)
        ])
        
        mainStack.addArrangedSubview(createRow(keys: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]))
        mainStack.addArrangedSubview(createRow(keys: ["a", "s", "d", "f", "g", "h", "j", "k", "l"], sidePadding: 20))
        
        // Row 3 (Shift)
        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.spacing = 6
        row3.distribution = .fillProportionally
        
        self.shiftButton = createButton(title: "⇧", isSpecial: true)
        self.shiftButton?.tag = 101 // Shift Tag
        let backBtn = createButton(title: "⌫", isSpecial: true)
        
        row3.addArrangedSubview(shiftButton!)
        for key in ["z", "x", "c", "v", "b", "n", "m"] {
            row3.addArrangedSubview(createButton(title: key))
        }
        row3.addArrangedSubview(backBtn)
        
        NSLayoutConstraint.activate([
            shiftButton!.widthAnchor.constraint(equalTo: backBtn.widthAnchor),
            shiftButton!.widthAnchor.constraint(equalToConstant: 42)
        ])
        mainStack.addArrangedSubview(row3)
        
        // Row 4
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.spacing = 6
        row4.distribution = .fillProportionally
        
        self.modeButton = createButton(title: "123", isSpecial: true)
        self.modeButton?.tag = 102 // Mode Tag
        let emojiBtn = createButton(title: "☺", isSpecial: true)
        let spaceBtn = createButton(title: "space", isSpecial: false)
        let returnBtn = createButton(title: "return", isSpecial: true)
        
        row4.addArrangedSubview(modeButton!)
        row4.addArrangedSubview(emojiBtn)
        row4.addArrangedSubview(spaceBtn)
        row4.addArrangedSubview(returnBtn)
        
        NSLayoutConstraint.activate([
            modeButton!.widthAnchor.constraint(equalTo: emojiBtn.widthAnchor),
            spaceBtn.widthAnchor.constraint(greaterThanOrEqualTo: emojiBtn.widthAnchor, multiplier: 4),
            returnBtn.widthAnchor.constraint(equalTo: emojiBtn.widthAnchor, multiplier: 1.5)
        ])
        mainStack.addArrangedSubview(row4)
        
        updateShiftUI()
    }
    
    func createChip(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 14
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(.black, for: .normal)
        return btn
    }
    
    func createRow(keys: [String], sidePadding: CGFloat = 0) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 6
        if sidePadding > 0 {
            stack.layoutMargins = UIEdgeInsets(top: 0, left: sidePadding, bottom: 0, right: sidePadding)
            stack.isLayoutMarginsRelativeArrangement = true
        }
        for key in keys {
            stack.addArrangedSubview(createButton(title: key))
        }
        return stack
    }
    
    func createButton(title: String, isSpecial: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.layer.cornerRadius = 5
        
        if isSpecial {
             button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
             button.backgroundColor = UIColor(white: 0.65, alpha: 1.0)
        } else {
             // Character Keys
             button.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .regular)
             button.backgroundColor = .white
             
             // FIX: Only add to letterButtons if it's one of the 26 QWERTY keys.
             // We can check if the title is a single letter (a-z).
             // 'space' has length 5, so it won't be added.
             if title.count == 1 {
                 letterButtons.append(button)
             }
        }
        
        button.setTitleColor(.black, for: .normal)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
        button.layer.shadowOpacity = 0.35
        
        button.addTarget(self, action: #selector(didTapKey(_:)), for: .touchUpInside)
        return button
    }
    
    @objc func didTapKey(_ sender: UIButton) {
        let title = sender.title(for: .normal) ?? ""
        let proxy = self.textDocumentProxy
        
        // Use Tags for reliable identification
        if sender.tag == 101 { // Shift
             handleShiftTap()
             return
        }
        
        if sender.tag == 102 { // Mode (123)
            toggleSymbols()
            return
        }
        
        switch title {
        case "space": proxy.insertText(" ")
        case "⌫": proxy.deleteBackward()
        case "return": proxy.insertText("\n")
        case "☺": break
        default:
            // Prevent accidentally typing control labels if logic fails
            if title == "123" || title == "ABC" || title == "#+=" || title == "Shift" {
                break
            }
            
            proxy.insertText(title)
            
            if !isSymbols && shiftState == .on {
                 shiftState = .off
                 updateShiftUI()
            }
        }
    }
    
    func toggleSymbols() {
        isSymbols = !isSymbols
        isMoreSymbols = false // Reset
        
        if isSymbols {
            modeButton?.setTitle("ABC", for: .normal)
            // Replace Shift with #+=
            shiftButton?.setTitle("#+=", for: .normal)
        } else {
            modeButton?.setTitle("123", for: .normal)
            updateShiftUI() // Restore icon
        }
        updateKeys()
    }
    
    func handleShiftTap() {
        if isSymbols {
             // Toggle More Symbols
             isMoreSymbols = !isMoreSymbols
             if isMoreSymbols {
                  shiftButton?.setTitle("123", for: .normal) // Button to go back
             } else {
                  shiftButton?.setTitle("#+=", for: .normal)
             }
             updateKeys()
             return
        }
    
        // Normal Shift Logic
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
    
    func updateShiftUI() {
        if isSymbols { return }
        
        // Shift Button Visuals
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
        // Remove strict count check to avoid silent failures
        // guard letterButtons.count == 26 else { return }
        
        let qwertyArray = Array(qwertyChars)
        let symbolArray = Array(symbolChars)
        // Pad extra array to ensure safety
        var extraString = extraSymbolChars
        while extraString.count < 26 { extraString += " " }
        let extraArray = Array(extraString)
        
        for (index, btn) in letterButtons.enumerated() {
            // Safety check for indices
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

    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {}
}
