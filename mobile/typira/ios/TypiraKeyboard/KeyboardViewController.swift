//
//  KeyboardViewController.swift
//  TypiraKeyboard
//
//  Created by Typira Agent on 2025.
//

import UIKit
import AVFoundation

class KeyboardViewController: UIInputViewController {

    enum ShiftState { case off, on, locked }
    enum ActiveView { case main, agent, voice }

    @IBOutlet var nextKeyboardButton: UIButton!
    
    // State
    var activeView: ActiveView = .main
    var shiftState: ShiftState = .off
    var isSymbols = false
    var isMoreSymbols = false
    var isEmojiView = false
    
    // Audio State
    var audioRecorder: AVAudioRecorder?
    var isRecording = false
    var recordingURL: URL?
    
    var lastShiftPressTime: Double = 0
    let doubleTapTimeout: Double = 0.3
    
    // UI Elements (Exposed to Extensions)
    var letterButtons = [UIButton]()
    let qwertyChars = "qwertyuiopasdfghjklzxcvbnm"
    let symbolChars = "1234567890-/:;()$&@\".,?!'  " 
    let extraSymbolChars = "[]{}#%^*+=_\\|~<>€£¥•.,?!'  "
    
    var qwertyRowsStack: UIStackView?
    var agentHubView: UIView?
    var emojiScrollView: UIScrollView?
    var emojiButton: UIButton?
    var shiftButton: UIButton?
    var modeButton: UIButton?
    var suggestionLabel: UILabel?
    
    // Smart Suggestion Logic
    var lastSuggestedCompletion: String = ""
    var lastTypedLength: Int = 0
    var suggestionTimer: Timer?
    var currentTask: URLSessionDataTask?
    var isLastKeyWordBoundary: Bool = false
    
    deinit {
        suggestionTimer?.invalidate()
        suggestionTimer = nil
        suggestionLabel = nil
        audioRecorder?.stop()
        audioRecorder = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func showView(_ viewType: ActiveView) {
        activeView = viewType
        
        qwertyRowsStack?.isHidden = (viewType != .main)
        emojiScrollView?.isHidden = true 
        agentHubView?.isHidden = (viewType != .agent)
        
        if viewType == .main {
            emojiButton?.setTitle("☺", for: .normal)
            isEmojiView = false
        }
        
        UIView.transition(with: self.view, duration: 0.2, options: .transitionCrossDissolve, animations: nil)
    }

    func toggleEmojiView() {
        if activeView != .main { showView(.main) }
        
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
}
