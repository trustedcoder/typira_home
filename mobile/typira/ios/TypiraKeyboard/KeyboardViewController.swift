//
//  KeyboardViewController.swift
//  TypiraKeyboard
//
//  Created by Typira Agent on 2025.
//

import UIKit

class KeyboardViewController: UIInputViewController {

    @IBOutlet var nextKeyboardButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardLayout()
    }
    
    func setupKeyboardLayout() {
        // Remove existing views
        self.view.subviews.forEach { $0.removeFromSuperview() }
        
        // Background Color
        self.view.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
        
        // --- 1. Suggestion Strip ---
        let suggestionStrip = UIStackView()
        suggestionStrip.axis = .horizontal
        suggestionStrip.distribution = .fillProportionally
        suggestionStrip.spacing = 10
        suggestionStrip.translatesAutoresizingMaskIntoConstraints = false
        suggestionStrip.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        suggestionStrip.isLayoutMarginsRelativeArrangement = true
        
        // Placeholder AI Buttons
        for title in ["✨ Rewrite", "📅 Plan", "Reply"] {
            let btn = UIButton(type: .system)
            btn.setTitle(title, for: .normal)
            btn.backgroundColor = .white
            btn.layer.cornerRadius = 14
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            btn.setTitleColor(.black, for: .normal)
            suggestionStrip.addArrangedSubview(btn)
        }
        self.view.addSubview(suggestionStrip)
        
        // --- 2. Main Keyboard Stack ---
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fillEqually
        mainStack.spacing = 10 
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mainStack)
        
        // Constraints
        let safe = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            // Strip at top
            suggestionStrip.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 4),
            suggestionStrip.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            suggestionStrip.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            suggestionStrip.heightAnchor.constraint(equalToConstant: 44),
            
            // Main Stack below Strip
            mainStack.topAnchor.constraint(equalTo: suggestionStrip.bottomAnchor, constant: 4),
            mainStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -4),
            mainStack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -4)
        ])
        
        // --- 3. Key Rows ---
        // Row 1
        mainStack.addArrangedSubview(createRow(keys: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]))
        
        // Row 2 (Padded)
        mainStack.addArrangedSubview(createRow(keys: ["a", "s", "d", "f", "g", "h", "j", "k", "l"], sidePadding: 20))
        
        // Row 3 (Shift, Z-M, Backspace)
        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.spacing = 6
        row3.distribution = .fillProportionally
        
        let shiftBtn = createButton(title: "⇧", isSpecial: true)
        let backBtn = createButton(title: "⌫", isSpecial: true)
        
        row3.addArrangedSubview(shiftBtn)
        for key in ["z", "x", "c", "v", "b", "n", "m"] {
            row3.addArrangedSubview(createButton(title: key))
        }
        row3.addArrangedSubview(backBtn)
        // Adjust widths: Shift/Back should be wider. standard key ~ 1.0. Shift ~ 1.3
        // We will just let fillProportionally handle it by giving text content some weight or constraint?
        // Let's set constraint relative to height.
        // Actually simplest is to ensure Shift and Backspace match width
        NSLayoutConstraint.activate([
            shiftBtn.widthAnchor.constraint(equalTo: backBtn.widthAnchor),
            shiftBtn.widthAnchor.constraint(equalToConstant: 42) // Min width
        ])
        
        mainStack.addArrangedSubview(row3)
        
        // Row 4 (123, Emoji, Space, Return)
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.spacing = 6
        row4.distribution = .fillProportionally
        
        let modeBtn = createButton(title: "123", isSpecial: true)
        let emojiBtn = createButton(title: "☺", isSpecial: true) // Placeholder Emoji Icon
        let spaceBtn = createButton(title: "space", isSpecial: false)
        let returnBtn = createButton(title: "return", isSpecial: true)
        
        row4.addArrangedSubview(modeBtn)
        row4.addArrangedSubview(emojiBtn)
        row4.addArrangedSubview(spaceBtn)
        row4.addArrangedSubview(returnBtn)
        
        // Constraints for Row 4
        // Mode and Emoji same width
        // Space big
        // Return same as Mode/Emoji or slightly bigger
        NSLayoutConstraint.activate([
            modeBtn.widthAnchor.constraint(equalTo: emojiBtn.widthAnchor),
            spaceBtn.widthAnchor.constraint(greaterThanOrEqualTo: emojiBtn.widthAnchor, multiplier: 4),
            returnBtn.widthAnchor.constraint(equalTo: emojiBtn.widthAnchor, multiplier: 1.5)
        ])
        
        mainStack.addArrangedSubview(row4)
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
        
        // Larger Font
        if isSpecial {
             button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
             button.backgroundColor = UIColor(white: 0.65, alpha: 1.0)
        } else {
             // Character Keys
             button.titleLabel?.font = UIFont.systemFont(ofSize: 25, weight: .regular)
             button.backgroundColor = .white
        }
        
        button.setTitleColor(.black, for: .normal)
        
        // Shadow
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
        
        switch key {
        case "space": proxy.insertText(" ")
        case "⌫": proxy.deleteBackward()
        case "return": proxy.insertText("\n")
        default: proxy.insertText(key)
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {}
}
