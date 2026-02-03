import UIKit
import Foundation

extension KeyboardViewController {

class StickyOverlayFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        let copy = attributes.map { $0.copy() as! UICollectionViewLayoutAttributes }
        
        for attribute in copy {
            if attribute.representedElementCategory == .supplementaryView,
               attribute.representedElementKind == UICollectionView.elementKindSectionHeader {
                adjustHeaderAttributes(attribute)
            }
        }
        return copy
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attribute = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }
        adjustHeaderAttributes(attribute)
        return attribute
    }
    
    private func adjustHeaderAttributes(_ attributes: UICollectionViewLayoutAttributes) {
        guard let collectionView = self.collectionView,
              let dataSource = collectionView.dataSource as? KeyboardViewController else { return }
        
        let section = attributes.indexPath.section
        let title = dataSource.emojiSections[section].title
        let font = UIFont.systemFont(ofSize: 10, weight: .bold)
        let visualWidth = title.size(withAttributes: [.font: font]).width + 20 
        
        if let lastItemAttrs = self.layoutAttributesForItem(at: IndexPath(item: dataSource.emojiSections[section].emojis.count - 1, section: section)) {
            let sectionMaxX = lastItemAttrs.frame.maxX + self.sectionInset.right
            let limitX = sectionMaxX - visualWidth
            
            if attributes.frame.origin.x > limitX {
                attributes.frame.origin.x = limitX
            }
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}
    
    func setupKeyboardLayout() {
        letterButtons.removeAll()
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.view.backgroundColor = KeyboardViewController.keyboardBackgroundColor
        
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
        self.smartActionStack = smartActionStack
        smartActionStack.axis = .horizontal
        smartActionStack.spacing = 8
        smartActionStack.alignment = .center
        smartActionStack.translatesAutoresizingMaskIntoConstraints = false
        
        let smartStatusLabel = UILabel()
        self.smartStatusLabel = smartStatusLabel
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
            actionScrollView.heightAnchor.constraint(equalToConstant: 50),
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
        
        
        // QWERTY ROWS
        qwertyRowsStack = UIStackView()
        qwertyRowsStack?.axis = .vertical
        qwertyRowsStack?.distribution = .fillEqually
        qwertyRowsStack?.spacing = 10
        
        qwertyRowsStack?.addArrangedSubview(createRow(keys: ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]))
        
        // Row 2: Always 10 slots. Manager visibility & padding in updateKeys
        let row2 = createRow(keys: ["a", "s", "d", "f", "g", "h", "j", "k", "l", " "])
        qwertyRowsStack?.addArrangedSubview(row2)
        
        let row3 = UIStackView()
        row3.axis = .horizontal
        row3.spacing = 6
        row3.distribution = .fillEqually
        
        self.shiftButton = createButton(title: "⇧", isSpecial: true)
        self.shiftButton?.tag = 101
        
        let backBtn = createButton(title: "⌫", isSpecial: true)
        
        row3.addArrangedSubview(shiftButton!)
        let bottomRowKeys = ["z", "x", "c", "v", "b", "n", "m"]
        for key in bottomRowKeys {
            row3.addArrangedSubview(createButton(title: key))
        }
        row3.addArrangedSubview(backBtn)

        qwertyRowsStack?.addArrangedSubview(row3)
        
        mainStack.addArrangedSubview(qwertyRowsStack!)
        qwertyRowsStack?.heightAnchor.constraint(equalToConstant: 150).isActive = true

        // EMOJI VIEW CONTAINER
        let emojiContainer = UIStackView()
        emojiContainer.axis = .vertical
        emojiContainer.spacing = 0
        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        emojiContainer.isHidden = true
        emojiContainer.backgroundColor = KeyboardViewController.keyboardBackgroundColor // Native Keyboard Gray
        self.emojiView = emojiContainer
        

        
        // 2. Emoji Grid (UICollectionView)
        let layout = StickyOverlayFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 12 // 5pt between columns
        layout.sectionHeadersPinToVisibleBounds = true // Native Sticky Headers
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.backgroundColor = .clear // Transparent to show container gray
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "EmojiCell")
        cv.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "EmojiHeader")
        
        cv.dataSource = self
        cv.delegate = self
        self.emojiCollectionView = cv
        
        emojiContainer.addArrangedSubview(cv)
        
        // Remove old populateEmojis call since CollectionView handles it
        // populateEmojis(in: emojiContentStack)
        
        // 3. Bottom Tab Bar
        let tabBar = UIStackView()
        tabBar.axis = .horizontal
        tabBar.distribution = .fillEqually
        tabBar.spacing = 0
        tabBar.backgroundColor = .clear // Remove white background
        tabBar.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        // ABC Button (Back)
        let abcBtn = UIButton(type: .system)
        abcBtn.setTitle("ABC", for: .normal)
        abcBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular) // Native iOS style
        abcBtn.setTitleColor(.black, for: .normal)
        abcBtn.addTarget(self, action: #selector(toggleEmojiView), for: .touchUpInside)
        tabBar.addArrangedSubview(abcBtn)
        
        // Categories (Functional Icons)
        let categoryIcons = ["clock", "face.smiling", "hare", "fork.knife", "sportscourt", "car", "lightbulb", "number.circle", "flag"]
        
        for (index, _) in self.emojiSections.enumerated() {
            let iconName = index < categoryIcons.count ? categoryIcons[index] : "circle"
            let btn = UIButton(type: .system)
            btn.tag = index
            if #available(iOS 13.0, *) {
                btn.setImage(UIImage(systemName: iconName), for: .normal)
            } else {
                btn.setTitle("•", for: .normal)
            }
            btn.tintColor = .systemGray
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            btn.imageView?.contentMode = .scaleAspectFit
            btn.contentHorizontalAlignment = .center
            btn.contentVerticalAlignment = .center
            btn.addTarget(self, action: #selector(didTapCategoryIcon(_:)), for: .touchUpInside)
            tabBar.addArrangedSubview(btn)
        }
        
        // Delete Button
        let delBtn = UIButton(type: .system)
        if #available(iOS 13.0, *) {
            delBtn.setImage(UIImage(systemName: "delete.left"), for: .normal)
        } else {
            delBtn.setTitle("⌫", for: .normal)
        }
        delBtn.tintColor = .black
        delBtn.tag = 105 // Special tag for Emoji View Delete
        delBtn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        delBtn.imageView?.contentMode = .scaleAspectFit
        delBtn.contentHorizontalAlignment = .center
        delBtn.contentVerticalAlignment = .center
        delBtn.addTarget(self, action: #selector(didTapKey(_:)), for: .touchUpInside)
        // Hack: Map delete button to existing key handler logic if it expects title "⌫"
        // We'll handle this by ensuring didTapKey handles the image or we set accessibilityIdentifier
        
        tabBar.addArrangedSubview(delBtn)
        
        emojiContainer.addArrangedSubview(tabBar)
        
        mainStack.addArrangedSubview(emojiContainer)
        
        // Constraint to ensure grid takes remaining space
        emojiContainer.heightAnchor.constraint(equalToConstant: 260).isActive = true
        
        // BOTTOM ROW
        let bottomRow = UIStackView()
        self.bottomKeyRow = bottomRow
        bottomRow.axis = .horizontal
        bottomRow.spacing = 6
        bottomRow.distribution = .fillProportionally
        
        self.modeButton = createButton(title: "123", isSpecial: true)
        self.modeButton?.tag = 102
        
        // Globe (Next Keyboard) Button
        let globeBtn = createButton(title: "globe", isSpecial: true, isSymbol: true)
        globeBtn.tag = 104 // Next Keyboard
        
        self.emojiButton = createButton(title: "😀", isSpecial: true, isSymbol: true)
        self.emojiButton?.tag = 103
        let spaceBtn = createButton(title: "space", isSpecial: false)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSpacePan(_:)))
        spaceBtn.addGestureRecognizer(panGesture)
        
        let returnBtn = createButton(title: "return", isSpecial: true)
        
        bottomRow.addArrangedSubview(modeButton!)
        bottomRow.addArrangedSubview(globeBtn)
        bottomRow.addArrangedSubview(emojiButton!)
        bottomRow.addArrangedSubview(spaceBtn)
        bottomRow.addArrangedSubview(returnBtn)
        
        NSLayoutConstraint.activate([
            modeButton!.widthAnchor.constraint(equalTo: globeBtn.widthAnchor),
            globeBtn.widthAnchor.constraint(equalTo: emojiButton!.widthAnchor),
            spaceBtn.widthAnchor.constraint(greaterThanOrEqualTo: emojiButton!.widthAnchor, multiplier: 3), // Reduced multiplier to accommodate globe
            returnBtn.widthAnchor.constraint(equalTo: emojiButton!.widthAnchor, multiplier: 1.5),
            bottomRow.heightAnchor.constraint(equalToConstant: 45)
        ])
        mainStack.addArrangedSubview(bottomRow)
        
        showView(.main)
        updateShiftUI()
        self.view.layoutIfNeeded()
    }

    func createButton(title: String, isSpecial: Bool = false, isSymbol: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        
        if isSymbol {
            // Try explicit image, then Base64 fallback (Guaranteed)
            // Try explicit image (Assets or Bundle Resource)
            // Use same pattern as ic_ai_custom (simple named lookup + alwaysOriginal)
            if let image = UIImage(named: "ic_native_emoji") ?? UIImage(named: "ic_native_emoji.png") {
                button.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
                button.imageView?.contentMode = .scaleAspectFit
                button.setTitle("", for: .normal)

            } else if #available(iOS 13.0, *), let image = UIImage(systemName: title, withConfiguration: UIImage.SymbolConfiguration(pointSize: 21, weight: .medium)) {
                // SF Symbol Found
                button.setImage(image, for: .normal)
                button.tintColor = .black
                button.setTitle("", for: .normal)
            } else {
                // Fallback: Use Title (Emoji)
                button.setImage(nil, for: .normal)
                // Use Text Variation Selector (\u{FE0E}) to force monochrome (black & white)
                let icon = title.isEmpty ? "😀\u{FE0E}" : (title == "😀" ? "😀\u{FE0E}" : title)
                button.setTitle(icon, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 26)
                button.titleLabel?.adjustsFontSizeToFitWidth = true
                button.titleLabel?.minimumScaleFactor = 0.5
            }
        } else {
            button.setTitle(title, for: .normal)
            button.setImage(nil, for: .normal)
        }
        
        button.layer.cornerRadius = 6
        
        // Native iOS Colors
        let specialKeyColor = KeyboardViewController.standardSpecialKeyColor
        let charKeyColor = KeyboardViewController.standardCharKeyColor
        
        if isSpecial {
            if !isSymbol {
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            }
            button.backgroundColor = specialKeyColor
            
            if title == "⌫" || title == "⇧" {
                button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
            }
        } else {
            if title == "space" {
                button.setTitle("space", for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .regular)
            } else {
                button.titleLabel?.font = UIFont.systemFont(ofSize: 26, weight: .regular)
            }
            button.backgroundColor = charKeyColor
            
            if !isSpecial && title.count == 1 {
                letterButtons.append(button)
            }
        }
        
        button.setTitleColor(.black, for: .normal)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 0
        button.layer.shadowOpacity = 0.3
        
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
            if let image = UIImage(named: "ic_ai_custom") {
                btn.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
                btn.imageView?.contentMode = .scaleAspectFit
            }
            btn.contentHorizontalAlignment = .fill
            btn.contentVerticalAlignment = .fill
            
            // Set fixed size for the Hub button to match parent/row height approx
            btn.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                btn.widthAnchor.constraint(equalToConstant: 50),
                btn.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            btn.accessibilityIdentifier = actionId
            btn.tag = 999 // Hub Tag
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
        
        btn.accessibilityIdentifier = actionId
        btn.tag = (actionId == "hub") ? 999 : 0
        
        // Fix: Use didTapAgentAction or didTapSuggestion properly depending on context
        // This was used for action strip buttons
        btn.addTarget(self, action: #selector(didTapActionChip(_:)), for: .touchUpInside)
        return btn
    }



}
