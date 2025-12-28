//
//  KeyboardViewController.swift
//  TypiraKeyboard
//
//  Created by Typira Agent on 2025.
//

import UIKit
import AVFoundation

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
    private var isEmojiView = false
    
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false
    private var recordingURL: URL?
    
    private let synthesizer = AVSpeechSynthesizer()
    
    var lastShiftPressTime: Double = 0
    let doubleTapTimeout: Double = 0.3
    
    // UI Elements
    var letterButtons = [UIButton]()
    let qwertyChars = "qwertyuiopasdfghjklzxcvbnm"
    let symbolChars = "1234567890-/:;()$&@\".,?!'  " 
    let extraSymbolChars = "[]{}#%^*+=_\\|~<>€£¥•.,?!'  "
    
    var qwertyRowsStack: UIStackView?
    var emojiScrollView: UIScrollView?
    var emojiButton: UIButton?
    var shiftButton: UIButton?
    var modeButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardLayout()
    }

    func toggleEmojiView() {
        isEmojiView = !isEmojiView
        if isEmojiView {
            qwertyRowsStack?.isHidden = true
            emojiScrollView?.isHidden = false
            emojiButton?.setTitle("ABC", for: .normal)
        } else {
            qwertyRowsStack?.isHidden = false
            emojiScrollView?.isHidden = true
            emojiButton?.setTitle("☺", for: .normal)
        }
        self.view.layoutIfNeeded()
    }

    func populateEmojis(in stack: UIStackView) {
        let emojiGroups: [[String]] = [
            ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗"],
            ["🤔", "🤭", "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😦", "😧", "😮", "😲", "🥱", "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮", "🤧", "🥵", "🥶", "😷", "🤒", "🤕", "🤑", "🤠", "😈", "👿", "👹", "👺", "🤡", "💩", "👻", "💀", "☠️", "👽", "👾", "🤖", "🎃", "😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"],
            ["🤲", "👐", "🙌", "👏", "🤝", "👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘", "👌", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚", "🖐", "🖖", "👋", "🤙", "💪", "🖕", "✍️", "🙏", "💍", "💄", "💋", "👄", "👅", "👂", "👃", "👣", "👁", "👀", "🧠", "🗣", "👤", "👥"],
            ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵", "🙈", "🙉", "🙊", "🐒", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐞", "🐜", "🦟", "🦗", "🕷", "🕸", "🦂", "🐢", "🐍", "🦎", "🦖", "🦕", "🐙", "🦑", "🦐", "🦞", "🦀", "🐡", "🐠", "🐟", "🐬", "🐳", "🐋", "🦈", "🐊", "🐅", "🐆", "🦓", "🦍", "🦧", "🐘", "🦛", "🦏", "🐪", "🐫", "🦒", "🦘", "🐃", "🐂", "🐄", "🐎", "🐖", "🐏", "🐑", "🦙", "🐐", "🦌", "🐕", "🐩", "🦮", "🐕‍🦺", "🐈", "🐓", "🦃", "🦚", "🦜", "🦢", "🦩", "🕊", "🐇", "🦝", "🦨", "🦡", "🦦", "🦥", "🐁", "🐀", "🐿", "🦔", "🐾", "🐉", "🐲", "🌵", "🎄", "🌲", "🌳", "🌴", "🌱", "🌿", "☘️", "🍀", "🎍", "🎋", "🍃", "🍂", "🍁", "🍄", "🐚", "🌾", "💐", "🌷", "🌹", "🥀", "🌺", "🌸", "🌼", "🌻", "🌞", "🌝", "🌛", "🌜", "🌚", "🌕", "🌖", "🌗", "🌘", "🌑", "🌒", "🌓", "🌔", "🌙", "🌎", "🌍", "🌏", "🪐", "💫", "⭐️", "🌟", "✨", "⚡️", "☄️", "💥", "🔥", "🌪", "🌈", "☀️", "🌤", "⛅️", "🌥", "☁️", "🌦", "🌧", "⛈", "🌩", "🌨", "❄️", "☃️", "⛄️", "🌬", "💨", "💧", "💦", "☔️", "☂️", "🌊", "🌫"]
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
                
                // Add a row every 8 emojis
                if (index + 1) % 8 == 0 {
                    stack.addArrangedSubview(row)
                    row = UIStackView()
                    row.axis = .horizontal
                    row.distribution = .fillEqually
                    row.spacing = 4
                }
            }
            // Add remaining emojis in the group
            if !row.arrangedSubviews.isEmpty {
                // Pad the row to maintain alignment
                while row.arrangedSubviews.count < 8 {
                    row.addArrangedSubview(UIView())
                }
                stack.addArrangedSubview(row)
            }
            
            // Add a spacer between groups
            let spacer = UIView()
            spacer.heightAnchor.constraint(equalToConstant: 20).isActive = true
            stack.addArrangedSubview(spacer)
        }
    }
    func setupKeyboardLayout() {
        letterButtons.removeAll()
        self.view.subviews.forEach { $0.removeFromSuperview() }
        self.view.backgroundColor = UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
        
        let suggestionScrollView = UIScrollView()
        suggestionScrollView.translatesAutoresizingMaskIntoConstraints = false
        suggestionScrollView.showsHorizontalScrollIndicator = false
        self.view.addSubview(suggestionScrollView)

        let suggestionStrip = UIStackView()
        suggestionStrip.axis = .horizontal
        suggestionStrip.distribution = .equalSpacing
        suggestionStrip.spacing = 10
        suggestionStrip.translatesAutoresizingMaskIntoConstraints = false
        suggestionStrip.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        suggestionStrip.isLayoutMarginsRelativeArrangement = true
        
        for title in ["✨ Rewrite", "📅 Plan", "🧠 Remember", "🎙️", "🔊 Listen", "Reply"] {
            let btn = createChip(title: title)
            suggestionStrip.addArrangedSubview(btn)
        }
        suggestionScrollView.addSubview(suggestionStrip)
        
        // mainStack - will contain [qwertyRowsStack OR emojiScrollView] and then row4
        let mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.distribution = .fill 
        mainStack.spacing = 10 
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(mainStack)
        
        let safe = self.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            suggestionScrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 4),
            suggestionScrollView.leadingAnchor.constraint(equalTo: safe.leadingAnchor),
            suggestionScrollView.trailingAnchor.constraint(equalTo: safe.trailingAnchor),
            suggestionScrollView.heightAnchor.constraint(equalToConstant: 44),
            
            suggestionStrip.topAnchor.constraint(equalTo: suggestionScrollView.topAnchor),
            suggestionStrip.leadingAnchor.constraint(equalTo: suggestionScrollView.leadingAnchor),
            suggestionStrip.trailingAnchor.constraint(equalTo: suggestionScrollView.trailingAnchor),
            suggestionStrip.bottomAnchor.constraint(equalTo: suggestionScrollView.bottomAnchor),
            suggestionStrip.heightAnchor.constraint(equalTo: suggestionScrollView.heightAnchor),

            mainStack.topAnchor.constraint(equalTo: suggestionScrollView.bottomAnchor, constant: 4),
            mainStack.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 4),
            mainStack.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -4),
            mainStack.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -4)
        ])
        
        // --- QWERTY ROWS (Rows 1-3) ---
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
        qwertyRowsStack?.addArrangedSubview(row3)
        
        mainStack.addArrangedSubview(qwertyRowsStack!)
        // Ensure qwertyRowsStack also has a fixed height or similar to prevent jitter
        qwertyRowsStack?.heightAnchor.constraint(equalToConstant: 220).isActive = true

        // --- EMOJI SCROLL VIEW ---
        emojiScrollView = UIScrollView()
        emojiScrollView?.isHidden = true
        emojiScrollView?.translatesAutoresizingMaskIntoConstraints = false
        // Important: give it a background color so we can see it during debug if empty
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
            // Give the scroll view a height constraint so it doesn't collapse in the stack view
            emojiScrollView!.heightAnchor.constraint(equalToConstant: 220)
        ])
        
        populateEmojis(in: emojiStack)
        mainStack.addArrangedSubview(emojiScrollView!)
        
        // --- ROW 4 (Always visible) ---
        let row4 = UIStackView()
        row4.axis = .horizontal
        row4.spacing = 6
        row4.distribution = .fillProportionally
        
        self.modeButton = createButton(title: "123", isSpecial: true)
        self.modeButton?.tag = 102 // Mode Tag
        self.emojiButton = createButton(title: "☺", isSpecial: true)
        self.emojiButton?.tag = 103 // Emoji Tag
        let spaceBtn = createButton(title: "space", isSpecial: false)
        
        // Cursor Control Gesture
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
            row4.heightAnchor.constraint(equalToConstant: 50) // Fix row4 height
        ])
        mainStack.addArrangedSubview(row4)
        
        updateShiftUI()
        self.view.layoutIfNeeded()
    }
    
    func createChip(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.backgroundColor = .white
        btn.layer.cornerRadius = 14
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        btn.setTitleColor(.black, for: .normal)
        btn.addTarget(self, action: #selector(didTapSuggestion(_:)), for: .touchUpInside)
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

        if sender.tag == 103 { // Emoji Tag
            toggleEmojiView()
            return
        }
        
        switch title {
        case "space": proxy.insertText(" ")
        case "⌫": proxy.deleteBackward()
        case "return": proxy.insertText("\n")
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
        if isEmojiView { toggleEmojiView() }
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
        if isEmojiView { toggleEmojiView() }
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
    
    @objc func handleSpacePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        let threshold: CGFloat = 10.0
        
        if abs(translation.x) > threshold {
            let offset = translation.x > 0 ? 1 : -1
            self.textDocumentProxy.adjustTextPosition(byCharacterOffset: offset)
            // Reset translation to allow continuous movement
            gesture.setTranslation(.zero, in: self.view)
        }
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
    @objc func didTapSuggestion(_ sender: UIButton) {
        let title = sender.title(for: .normal) ?? ""
        if title == "✨ Rewrite" {
            handleRewriteAction()
            
            // Visual feedback
            let originalColor = sender.backgroundColor
            sender.backgroundColor = .cyan
            UIView.animate(withDuration: 1.0) {
                sender.backgroundColor = originalColor
            }
        } else if title == "🧠 Remember" {
            handleRememberAction()
            
            // Visual feedback
            let originalColor = sender.backgroundColor
            sender.backgroundColor = .green
            UIView.animate(withDuration: 1.0) {
                sender.backgroundColor = originalColor
            }
        } else if title == "🎙️" {
            handleMicAction()
        } else if title == "🔊 Listen" {
            handleListenAction()
        }
    }
    
    func handleMicAction() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
            
            let tempDir = FileManager.default.temporaryDirectory
            recordingURL = tempDir.appendingPathComponent("typira_voice.m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            print("🎙️ iOS Native Recording started: \(recordingURL?.path ?? "")")
            
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        isRecording = false
        audioRecorder?.stop()
        print("🎙️ iOS Native Recording stopped. Uploading...")
        
        if let url = recordingURL {
            uploadAudio(at: url)
        }
    }

    func uploadAudio(at url: URL) {
        let backendURL = URL(string: "http://localhost:8000/stt")!
        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio_file\"; filename=\"voice.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        
        do {
            let audioData = try Data(contentsOf: url)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = body
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("Upload failed: \(error.localizedDescription)")
                    return
                }
                
                if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let transcript = json["transcript"] as? String {
                    DispatchQueue.main.async {
                        self?.textDocumentProxy.insertText(transcript)
                        print("✅ iOS Voice Inserted: \(transcript)")
                    }
                }
            }.resume()
            
        } catch {
            print("Failed to read audio data: \(error.localizedDescription)")
        }
    }
    
    func handleListenAction() {
        // Read text from the proxy
        let text = textDocumentProxy.documentContextBeforeInput ?? ""
        if text.isEmpty { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
        print("🔊 iOS Native TTS Speaking: \(text)")
    }
    
    func handleRememberAction() {
        if let text = UIPasteboard.general.string, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if text.count < 3 { return }
            
            // Local store
            let prefs = UserDefaults.standard
            var memories = prefs.stringArray(forKey: "typira_memories") ?? []
            if !memories.contains(text) {
                memories.append(text)
                prefs.set(memories, forKey: "typira_memories")
            }
            
            // Sync to Backend
            syncMemoryToBackend(text: text)
        }
    }
    
    func handleRewriteAction() {
        let text = textDocumentProxy.documentContextBeforeInput ?? ""
        if text.isEmpty { return }
        
        // Fetch memories for context
        let prefs = UserDefaults.standard
        let memories = prefs.stringArray(forKey: "typira_memories") ?? []
        let context = memories.joined(separator: ". ")
        
        requestRewrite(text: text, context: context)
    }
    
    func requestRewrite(text: String, context: String) {
        guard let url = URL(string: "http://localhost:8000/rewrite") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters = [
            "text": text,
            "context": context,
            "tone": "professional"
        ]
        
        let bodyString = bodyParameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rewritten = json["rewritten_text"] as? String {
                DispatchQueue.main.async {
                    // Replace the existing text? Or just append?
                    // For AI, we usually replace the sentence or just insert.
                    self?.textDocumentProxy.insertText("\n" + rewritten)
                    print("✅ iOS Rewrite Complete")
                }
            }
        }.resume()
    }
    
    func syncMemoryToBackend(text: String) {
        guard let url = URL(string: "http://localhost:8000/remember") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Failed to sync memory: \(error.localizedDescription)")
            } else {
                print("✅ Memory synced to backend")
            }
        }.resume()
    }
}
