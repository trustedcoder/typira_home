import UIKit
import Foundation

extension KeyboardViewController {
    
    func setupKeyboardLayout() {
        letterButtons.removeAll()
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.view.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
        
        let toolbarStack = UIStackView()
        toolbarStack.axis = .vertical
        toolbarStack.spacing = 0
        toolbarStack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(toolbarStack)
        
        // --- ROW 1: AI ACTION STRIP ---
        let actionScrollView = UIScrollView()
        actionScrollView.showsHorizontalScrollIndicator = false
        actionScrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Main Container for Action Strip (Hub Left, Spacer, Tools Right)
        let actionStrip = UIStackView()
        actionStrip.axis = .horizontal
        actionStrip.alignment = .center
        actionStrip.distribution = .fill // Important for spacer
        actionStrip.spacing = 8
        actionStrip.translatesAutoresizingMaskIntoConstraints = false
        actionStrip.layoutMargins = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        actionStrip.isLayoutMarginsRelativeArrangement = true
        
        // 1. Hub (Left)
        let hubBtn = createChip(actionId: "hub")
        actionStrip.addArrangedSubview(hubBtn)
        
        // 2. Spacer (Middle) - Pushes tools to right
        let spacerView = UIView()
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.translatesAutoresizingMaskIntoConstraints = false
        // Ensure spacer takes up available space
        actionStrip.addArrangedSubview(spacerView)
        NSLayoutConstraint.activate([
            spacerView.widthAnchor.constraint(greaterThanOrEqualToConstant: 20) // Minimum separation
        ])
        
        // 3. Tools (Right) - Rewrite, Paste, Mic (Plan Removed)
        let toolsStack = UIStackView()
        toolsStack.axis = .horizontal
        toolsStack.spacing = 16
        toolsStack.distribution = .fillEqually
        
        let toolActions = [
            (id: "rewrite", icon: "sparkles"),
            (id: "paste", icon: "doc.on.clipboard"),
            (id: "mic", icon: "mic.fill")
        ]
        
        for action in toolActions {
            let btn = createChip(systemIcon: action.icon, actionId: action.id)
            toolsStack.addArrangedSubview(btn)
        }
        actionStrip.addArrangedSubview(toolsStack)
        
        actionScrollView.addSubview(actionStrip)
        toolbarStack.addArrangedSubview(actionScrollView)
        
        // --- ROW 2: SUGGESTION AREA (Thought Stream) ---
        let suggestionScrollView = UIScrollView()
        suggestionScrollView.showsVerticalScrollIndicator = true
        suggestionScrollView.translatesAutoresizingMaskIntoConstraints = false
        suggestionScrollView.backgroundColor = UIColor(white: 1.0, alpha: 0.5)
        
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        label.textColor = .darkGray
        label.text = "Typira is thinking..."
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSuggestionLabel(_:)))
        label.addGestureRecognizer(tap)
        
        self.suggestionLabel = label
        suggestionScrollView.addSubview(label)
        toolbarStack.addArrangedSubview(suggestionScrollView)
        
        // --- ROW 3: SMART ACTION GRID (Scrollable Chips) ---
        let smartActionScrollView = UIScrollView()
        smartActionScrollView.showsVerticalScrollIndicator = false
        smartActionScrollView.showsHorizontalScrollIndicator = true
        smartActionScrollView.translatesAutoresizingMaskIntoConstraints = false
        smartActionScrollView.backgroundColor = UIColor(red: 240/255, green: 242/255, blue: 245/255, alpha: 1.0)
        
        // Container for Smart Chips
        let smartActionStack = UIStackView()
        smartActionStack.axis = .horizontal
        smartActionStack.spacing = 8
        smartActionStack.alignment = .center
        smartActionStack.translatesAutoresizingMaskIntoConstraints = false
        
        let smartStatusLabel = UILabel()
        smartStatusLabel.text = "Waiting for intent..."
        smartStatusLabel.font = UIFont.italicSystemFont(ofSize: 12)
        smartStatusLabel.textColor = .systemGray
        smartActionStack.addArrangedSubview(smartStatusLabel)
        
        smartActionScrollView.addSubview(smartActionStack)
        toolbarStack.addArrangedSubview(smartActionScrollView)
        
        // --- MAIN AREA ---
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fill 
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mainStack)
        
        let safe = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            toolbarStack.topAnchor.constraint(equalTo: self.view.topAnchor),
            toolbarStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            toolbarStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            
            // Row 1 Height Increased to 60
            actionScrollView.heightAnchor.constraint(equalToConstant: 60),
            actionStrip.topAnchor.constraint(equalTo: actionScrollView.topAnchor),
            actionStrip.leadingAnchor.constraint(equalTo: actionScrollView.leadingAnchor),
            actionStrip.trailingAnchor.constraint(equalTo: actionScrollView.trailingAnchor),
            actionStrip.bottomAnchor.constraint(equalTo: actionScrollView.bottomAnchor),
            actionStrip.heightAnchor.constraint(equalTo: actionScrollView.heightAnchor),
            actionStrip.widthAnchor.constraint(equalTo: actionScrollView.widthAnchor),
            
            // Row 2: Smart Action Grid (50 height)
            smartActionScrollView.heightAnchor.constraint(equalToConstant: 50),
            smartActionStack.topAnchor.constraint(equalTo: smartActionScrollView.topAnchor),
            smartActionStack.leadingAnchor.constraint(equalTo: smartActionScrollView.leadingAnchor, constant: 12),
            smartActionStack.trailingAnchor.constraint(equalTo: smartActionScrollView.trailingAnchor, constant: -12),
            smartActionStack.bottomAnchor.constraint(equalTo: smartActionScrollView.bottomAnchor),
            smartActionStack.heightAnchor.constraint(equalTo: smartActionScrollView.heightAnchor),

            // Row 3: Suggestion Text Box (60 height)
            suggestionScrollView.heightAnchor.constraint(equalToConstant: 60),
            label.topAnchor.constraint(equalTo: suggestionScrollView.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: suggestionScrollView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: suggestionScrollView.trailingAnchor, constant: -12),
            label.bottomAnchor.constraint(equalTo: suggestionScrollView.bottomAnchor, constant: -8),
            label.widthAnchor.constraint(equalTo: suggestionScrollView.widthAnchor, constant: -24),

            mainStack.topAnchor.constraint(equalTo: toolbarStack.bottomAnchor, constant: 4),
            mainStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -4),
            mainStack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -4)
        ])
        
        setupAgentHub(in: mainStack)
        
        // QWERTY ROWS
        qwertyRowsStack = UIStackView()
        qwertyRowsStack?.axis = .vertical
        qwertyRowsStack?.distribution = .fillEqually
        qwertyRowsStack?.spacing = 10
        
        qwertyRowsStack?.addArrangedSubview(createRow(keys: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]))
        qwertyRowsStack?.addArrangedSubview(createRow(keys: ["a", "s", "d", "f", "g", "h", "j", "k", "l"], sidePadding: 20))
        
        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.spacing = 6
        row3.distribution = .fillProportionally
        
        self.shiftButton = createButton(title: "⇧", isSpecial: true)
        self.shiftButton?.tag = 101
        let backBtn = createButton(title: "⌫", isSpecial: true)
        
        row3.addArrangedSubview(shiftButton!)
        var bottomRowKeys = ["z", "x", "c", "v", "b", "n", "m"]
        for key in bottomRowKeys {
            row3.addArrangedSubview(createButton(title: key))
        }
        row3.addArrangedSubview(backBtn)
        
        NSLayoutConstraint.activate([
            shiftButton!.widthAnchor.constraint(equalTo: backBtn.widthAnchor),
            shiftButton!.widthAnchor.constraint(equalToConstant: 42)
        ])
        qwertyRowsStack?.addArrangedSubview(row3)
        
        mainStack.addArrangedSubview(qwertyRowsStack!)
        qwertyRowsStack?.heightAnchor.constraint(equalToConstant: 220).isActive = true

        // EMOJI VIEW
        emojiScrollView = UIScrollView()
        emojiScrollView?.isHidden = true
        emojiScrollView?.translatesAutoresizingMaskIntoConstraints = false
        emojiScrollView?.backgroundColor = .clear 
        
        let emojiStack = UIStackView()
        emojiStack.axis = .vertical
        emojiStack.spacing = 12
        emojiStack.translatesAutoresizingMaskIntoConstraints = false
        emojiScrollView?.addSubview(emojiStack)
        
        NSLayoutConstraint.activate([
            emojiStack.topAnchor.constraint(equalTo: emojiScrollView!.topAnchor, constant: 8),
            emojiStack.leadingAnchor.constraint(equalTo: emojiScrollView!.leadingAnchor, constant: 4),
            emojiStack.trailingAnchor.constraint(equalTo: emojiScrollView!.trailingAnchor, constant: -4),
            emojiStack.bottomAnchor.constraint(equalTo: emojiScrollView!.bottomAnchor, constant: -8),
            emojiStack.widthAnchor.constraint(equalTo: emojiScrollView!.widthAnchor, constant: -8),
            emojiScrollView!.heightAnchor.constraint(equalToConstant: 220)
        ])
        
        populateEmojis(in: emojiStack)
        mainStack.addArrangedSubview(emojiScrollView!)
        
        // BOTTOM ROW
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.spacing = 6
        row4.distribution = .fillProportionally
        
        self.modeButton = createButton(title: "123", isSpecial: true)
        self.modeButton?.tag = 102
        self.emojiButton = createButton(title: "☺", isSpecial: true)
        self.emojiButton?.tag = 103
        let spaceBtn = createButton(title: "space", isSpecial: false)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSpacePan(_:)))
        spaceBtn.addGestureRecognizer(panGesture)
        
        let returnBtn = createButton(title: "return", isSpecial: true)
        
        row4.addArrangedSubview(modeButton!)
        row4.addArrangedSubview(emojiButton!)
        row4.addArrangedSubview(spaceBtn)
        row4.addArrangedSubview(returnBtn)
        
        NSLayoutConstraint.activate([
            modeButton!.widthAnchor.constraint(equalTo: emojiButton!.widthAnchor),
            spaceBtn.widthAnchor.constraint(greaterThanOrEqualTo: emojiButton!.widthAnchor, multiplier: 4),
            returnBtn.widthAnchor.constraint(equalTo: emojiButton!.widthAnchor, multiplier: 1.5),
            row4.heightAnchor.constraint(equalToConstant: 50)
        ])
        mainStack.addArrangedSubview(row4)
        
        showView(.main)
        updateShiftUI()
        self.view.layoutIfNeeded()
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
             
            if !isSpecial && title.count == 1 {
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

    func createChip(title: String? = nil, systemIcon: String? = nil, actionId: String? = nil) -> UIButton {
        let btn = UIButton(type: .system)
        
        if actionId == "hub" {
            let image = UIImage(named: "ic_ai_custom")?.withRenderingMode(.alwaysOriginal)
            btn.setImage(image, for: .normal)
            btn.imageView?.contentMode = .scaleAspectFit
            btn.contentHorizontalAlignment = .fill
            btn.contentVerticalAlignment = .fill
            
            // Set fixed size for the Hub button to match parent/row height approx
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 70),
                btn.heightAnchor.constraint(equalToConstant: 70)
            ])
            
            btn.accessibilityIdentifier = actionId
        } else if let iconName = systemIcon {
            if #available(iOS 13.0, *) {
                let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
                let image = UIImage(systemName: iconName, withConfiguration: config)
                btn.setImage(image, for: .normal)
            } else {
                let emojiFallback: [String: String] = [
                    "square.grid.2x2.fill": "✨",
                    "sparkles": "✨",
                    "calendar": "📅",
                    "doc.on.clipboard": "📋",
                    "mic.fill": "🎙️"
                ]
                btn.setTitle(emojiFallback[iconName] ?? "AI", for: .normal)
            }
            btn.tintColor = .systemBlue
            btn.accessibilityIdentifier = actionId
        } else if let text = title {
            btn.setTitle(text, for: .normal)
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            btn.backgroundColor = .white
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
        }
        
        // Fix: Use didTapAgentAction or didTapSuggestion properly depending on context
        // This was used for action strip buttons
        btn.addTarget(self, action: #selector(didTapActionChip(_:)), for: .touchUpInside)
        return btn
    }

    func setupAgentHub(in mainStack: UIStackView) {
        let hub = UIStackView()
        hub.axis = .vertical
        hub.spacing = 15
        hub.isHidden = true
        hub.translatesAutoresizingMaskIntoConstraints = false
        self.agentHubView = hub
        
        let header = UIStackView()
        header.axis = .horizontal
        header.distribution = .equalSpacing
        let titleLabel = UILabel()
        titleLabel.text = "✨ Typira Agent Hub"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        let closeBtn = UIButton(type: .system)
        closeBtn.setTitle("Done", for: .normal)
        closeBtn.addTarget(self, action: #selector(closeAgentHub), for: .touchUpInside)
        header.addArrangedSubview(titleLabel)
        header.addArrangedSubview(closeBtn)
        hub.addArrangedSubview(header)

        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentStack)
        hub.addArrangedSubview(scrollView)
        
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Categories
        contentStack.addArrangedSubview(createAgentCategory(title: "Generation", color: .systemPurple, actions: ["Rewrite", "Social Post", "Article Draft", "Text-to-Image", "Text-to-Video"]))
        contentStack.addArrangedSubview(createAgentCategory(title: "Productivity", color: .systemBlue, actions: ["Smart Plan", "Set Reminder", "To-Do List", "Habit Tracker"]))
        contentStack.addArrangedSubview(createAgentCategory(title: "Insights", color: .systemGreen, actions: ["Daily Tip", "Time Stats", "Writing Style"]))

        mainStack.addArrangedSubview(hub)
        hub.heightAnchor.constraint(equalToConstant: 220).isActive = true
    }
    
    func createAgentCategory(title: String, color: UIColor, actions: [String]) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 8
        
        let label = UILabel()
        label.text = title.uppercased()
        label.font = UIFont.systemFont(ofSize: 11, weight: .black)
        label.textColor = color
        container.addArrangedSubview(label)
        
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 6
        
        var currentRow: UIStackView?
        for (index, action) in actions.enumerated() {
            if index % 2 == 0 {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.distribution = .fillEqually
                currentRow?.spacing = 6
                grid.addArrangedSubview(currentRow!)
            }
            
            let btn = UIButton(type: .system)
            btn.setTitle(action, for: .normal)
            btn.backgroundColor = .white
            btn.layer.cornerRadius = 8
            btn.setTitleColor(.black, for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
            btn.addTarget(self, action: #selector(didTapAgentAction(_:)), for: .touchUpInside)
            
            currentRow?.addArrangedSubview(btn)
        }
        
        if let lastRow = currentRow, lastRow.arrangedSubviews.count == 1 {
            lastRow.addArrangedSubview(UIView())
        }
        
        container.addArrangedSubview(grid)
        return container
    }
    
    @objc func closeAgentHub() {
        showView(.main)
    }

    @objc func didTapAgentAction(_ sender: UIButton) {
        let action = sender.title(for: .normal) ?? ""
        NSLog("Agent Action: \(action)")
        
        if action == "Rewrite" {
             handleRewriteAction()
             showView(.main)
        }
    }

    func populateEmojis(in stack: UIStackView) {
        let emojiGroups: [[String]] = [
            ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗"],
            ["🤔", "🤭", "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😦", "😧", "😮", "😲", "🥱", "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮", "🤧", "🥵", "🥶", "😷", "🤒", "🤕", "🤑", "🤠", "😈", "👿", "👹", "👺", "🤡", "💩", "👻", "💀", "☠️", "👽", "👾", "🤖", "🎃", "😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"]
        ]
        
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for group in emojiGroups {
            var row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 4
            
            for (index, emoji) in group.enumerated() {
                let btn = UIButton(type: .system)
                btn.setTitle(emoji, for: .normal)
                btn.titleLabel?.font = UIFont.systemFont(ofSize: 32)
                btn.addTarget(self, action: #selector(didTapKey(_:)), for: .touchUpInside)
                row.addArrangedSubview(btn)
                
                if (index + 1) % 8 == 0 {
                    stack.addArrangedSubview(row)
                    row = UIStackView()
                    row.axis = .horizontal
                    row.distribution = .fillEqually
                    row.spacing = 4
                }
            }
            if !row.arrangedSubviews.isEmpty {
                while row.arrangedSubviews.count < 8 {
                    row.addArrangedSubview(UIView())
                }
                stack.addArrangedSubview(row)
            }
            
            let spacer = UIView()
            spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
            stack.addArrangedSubview(spacer)
        }
    }
}
