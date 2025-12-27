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
    var lastShiftPressTime: Double = 0
    let doubleTapTimeout: Double = 0.3
    
    var letterButtons = [UIButton]()
    var shiftButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardLayout()
    }
    
    func setupKeyboardLayout() {
        letterButtons.removeAll()
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.view.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
        
        // Suggestion Strip
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
        
        let modeBtn = createButton(title: "123", isSpecial: true)
        let emojiBtn = createButton(title: "☺", isSpecial: true)
        let spaceBtn = createButton(title: "space", isSpecial: false)
        let returnBtn = createButton(title: "return", isSpecial: true)
        
        row4.addArrangedSubview(modeBtn)
        row4.addArrangedSubview(emojiBtn)
        row4.addArrangedSubview(spaceBtn)
        row4.addArrangedSubview(returnBtn)
        
        NSLayoutConstraint.activate([
            modeBtn.widthAnchor.constraint(equalTo: emojiBtn.widthAnchor),
            spaceBtn.widthAnchor.constraint(greaterThanOrEqualTo: emojiBtn.widthAnchor, multiplier: 4),
            returnBtn.widthAnchor.constraint(equalTo: emojiBtn.widthAnchor, multiplier: 1.5)
        ])
        mainStack.addArrangedSubview(row4)
        
        updateShiftUI() // Init
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
             button.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .regular)
             button.backgroundColor = .white
             letterButtons.append(button)
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
        let key = sender.title(for: .normal) ?? ""
        let proxy = self.textDocumentProxy
        
        // Handle Shift Special Case
        // Note: The button title might change (⇧ vs ⇪), so checking reference or tag is better.
        // But here we rely on the button action triggering based on original title?
        // Ah, if we change the title to '⇪', hitting it again will pass '⇪' to this function.
        if sender == shiftButton {
             handleShiftTap()
             return
        }
        
        switch key {
        case "space": proxy.insertText(" ")
        case "⌫": proxy.deleteBackward()
        case "return": proxy.insertText("\n")
        case "123", "☺": break
        default:
            proxy.insertText(key)
            if shiftState == .on {
                shiftState = .off
                updateShiftUI()
            }
        }
    }
    
    func handleShiftTap() {
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
            // Locked -> Off
            shiftState = .off
        }
        
        lastShiftPressTime = now
        updateShiftUI()
    }
    
    func updateShiftUI() {
        switch shiftState {
        case .off:
            shiftButton?.setTitle("⇧", for: .normal)
            shiftButton?.backgroundColor = UIColor(white: 0.65, alpha: 1.0)
            shiftButton?.setTitleColor(.black, for: .normal)
            updateLetters(upper: false)
        case .on:
            shiftButton?.setTitle("⇧", for: .normal)
            shiftButton?.backgroundColor = .white // Active look
            shiftButton?.setTitleColor(.black, for: .normal)
            updateLetters(upper: true)
        case .locked:
             shiftButton?.setTitle("⇪", for: .normal) // Lock Icon
             shiftButton?.backgroundColor = .white
             shiftButton?.setTitleColor(.black, for: .normal)
             updateLetters(upper: true)
        }
    }
    
    func updateLetters(upper: Bool) {
        for btn in letterButtons {
            guard let text = btn.title(for: .normal) else { continue }
            let newText = upper ? text.uppercased() : text.lowercased()
            btn.setTitle(newText, for: .normal)
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {}
}
