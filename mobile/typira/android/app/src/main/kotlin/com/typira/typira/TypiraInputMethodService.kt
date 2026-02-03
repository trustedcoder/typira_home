package com.typira.typira

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.ImageButton
import android.view.KeyEvent
import java.util.Locale
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.speech.tts.TextToSpeech
import android.view.inputmethod.ExtractedTextRequest
import org.json.JSONArray
import org.json.JSONObject

class TypiraInputMethodService : InputMethodService() {


    private enum class KeyboardState { MAIN, EMOJI }
    private var keyboardState = KeyboardState.MAIN
    
    private enum class ShiftState { OFF, ON, LOCKED }
    private var shiftState = ShiftState.OFF
    private var lastShiftPressTime: Long = 0
    private val DOUBLE_TAP_TIMEOUT = 300L

    private var isSymbols = false
    private var isMoreSymbols = false

    private val letterButtons = mutableListOf<Button>()
    private val qwertyChars = "qwertyuiopasdfghjklzxcvbnm"
    private val symbolChars = "1234567890-/:;()$&@\".,?!'  " 
    private val extraSymbolChars = "[]{}#%^*+=_\\|~<>€£¥•.,?!'  "

    // UI Components
    private lateinit var shiftIcon: ImageButton
    private lateinit var shiftText: Button
    private lateinit var modeButton: Button
    private lateinit var emojiButton: Button
    private lateinit var layoutQwerty: View
    private lateinit var layoutEmoji: View
    private lateinit var gridEmoji: android.widget.GridLayout
    private lateinit var tvSuggestion: android.widget.TextView
    private lateinit var backspaceButton: android.view.View
    private lateinit var smartActionContainer: android.widget.LinearLayout
    private lateinit var tvSmartStatus: android.widget.TextView
    
    // Logic
    private val suggestionHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private var suggestionRunnable: Runnable? = null
    private var contextBuffer = StringBuilder()
    
    private var tts: TextToSpeech? = null
    private var lastSuggestedCompletion: String = ""
    private var lastTypedLength: Int = 0
    private var currentSmartActions = mutableListOf<org.json.JSONObject>()

    // Services
    private lateinit var aiService: AIService
    private lateinit var audioService: AudioService
    private lateinit var uiManager: KeyboardUIManager
    private lateinit var historyManager: TypingHistoryManager

    override fun onCreate() {
        super.onCreate()
        aiService = AIService()
        audioService = AudioService()
        uiManager = KeyboardUIManager(this)
        historyManager = TypingHistoryManager(this, { message: String ->
            android.util.Log.d("TypiraUI", "Updating Suggestion TextView: $message")
            if (this::tvSuggestion.isInitialized) {
                tvSuggestion.text = message
                tvSuggestion.setBackgroundColor(android.graphics.Color.TRANSPARENT)
                if (message.contains("💡")) {
                    tvSuggestion.setTextColor(android.graphics.Color.parseColor("#1AA260")) // Google Green for suggestions
                } else {
                    tvSuggestion.setTextColor(android.graphics.Color.parseColor("#1A73E8")) // Google Blue for thoughts
                }
            }
        }, { actions: JSONArray ->
            android.util.Log.d("TypiraUI", "Received ${actions.length()} actions for rendering")
            renderActionChips(actions)
        }, { result: String ->
            android.util.Log.d("TypiraUI", "Received AI Result: $result")
            if (this::tvSuggestion.isInitialized) {
                lastSuggestedCompletion = result
                tvSuggestion.text = "$result (Tap to insert)"
                tvSuggestion.setTextColor(android.graphics.Color.BLACK)
                tvSuggestion.setBackgroundColor(android.graphics.Color.parseColor("#F1F8E9")) // Light highlight
            }
        })
    }

    override fun onCreateInputView(): View {
        val view = layoutInflater.inflate(R.layout.keyboard_view, null)
        setupTTS()
        setupKeyListeners(view)
        
        tvSuggestion = view.findViewById(R.id.tv_suggestion)
        smartActionContainer = view.findViewById(R.id.smart_action_container)
        tvSmartStatus = view.findViewById(R.id.tv_smart_status)
        
        return view
    }

    private fun renderActionChips(actions: JSONArray) {
        if (!this::smartActionContainer.isInitialized) return
        
        smartActionContainer.removeAllViews()
        currentSmartActions.clear()
        
        if (actions.length() == 0) {
            smartActionContainer.addView(tvSmartStatus)
            return
        }
        
        for (i in 0 until actions.length()) {
            val action = actions.getJSONObject(i)
            currentSmartActions.add(action)
            
            val label = action.getString("label")
            val actionId = action.getString("id")
            
            val button = Button(this).apply {
                text = label
                textSize = 12f
                isAllCaps = false
                val params = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                )
                params.setMargins(0, 0, 8, 0)
                layoutParams = params
                setOnClickListener {
                    onAgentActionClick(actionId)
                }
            }
            smartActionContainer.addView(button)
        }
    }

    private fun setupTTS() {
        tts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale.US
            }
        }
    }

    private fun setupKeyListeners(rootView: View) {
        layoutQwerty = rootView.findViewById(R.id.layout_qwerty)
        layoutEmoji = rootView.findViewById(R.id.layout_emoji)
        gridEmoji = rootView.findViewById(R.id.grid_emoji)

        backspaceButton = rootView.findViewById(R.id.key_backspace)
        backspaceButton.setOnClickListener { onKeyClick("⌫") }

        shiftIcon = rootView.findViewById(R.id.key_shift_icon)
        shiftIcon.setOnClickListener { handleShiftClick() }
        
        shiftText = rootView.findViewById(R.id.key_shift_text)
        shiftText.setOnClickListener { handleShiftClick() }

        emojiButton = rootView.findViewById<Button>(R.id.key_emoji)
        emojiButton.setOnClickListener { toggleEmojiView() }

        val enter = rootView.findViewById<Button>(R.id.key_enter)
        enter?.setOnClickListener { onKeyClick("return") }
        
        modeButton = rootView.findViewById<Button>(R.id.key_mode)
        modeButton.setOnClickListener { toggleSymbols() }

        val space = rootView.findViewById<Button>(R.id.key_space)
        space?.setOnClickListener { onKeyClick("space") }
        setupSpaceKeyTrackpad(space)

        rootView.findViewById<Button>(R.id.key_globe)?.setOnClickListener {
            val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as android.view.inputmethod.InputMethodManager
            imm.showInputMethodPicker()
        }

        // AI Action Toolbar
        val openAppListener = View.OnClickListener {
            val intent = packageManager.getLaunchIntentForPackage("com.typira.typira")
            intent?.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
        rootView.findViewById<View>(R.id.btn_hub)?.setOnClickListener(openAppListener)
        rootView.findViewById<View>(R.id.btn_rewrite_icon)?.setOnClickListener(openAppListener)
        rootView.findViewById<View>(R.id.btn_paste_icon)?.setOnClickListener { handleRememberAction() }
        rootView.findViewById<View>(R.id.btn_mic_icon)?.setOnClickListener { handleMicAction() }

        // Suggestion Toolbar
        tvSuggestion = rootView.findViewById(R.id.tv_suggestion)
        tvSuggestion.setOnClickListener { acceptSuggestion() }
        populateSuggestions("Typira is analyzing your context... (Tap to insert)")

        letterButtons.clear()
        findLetterKeys(rootView)
        
        updateShiftUI() 
        uiManager.populateEmojiGrid(gridEmoji) { emoji -> onKeyClick(emoji) }
    }

    private fun onKeyClick(keyText: String) {
        val inputConnection = currentInputConnection ?: return
        var isWordBoundary = false
        
        // Feed entire character to History Manager
        historyManager.onTextTyped(keyText, currentInputEditorInfo)
        
        when (keyText) {
            "⌫" -> {
                inputConnection.deleteSurroundingText(1, 0)
                if (contextBuffer.isNotEmpty()) contextBuffer.deleteCharAt(contextBuffer.length - 1)
                isWordBoundary = false
            }
            "space" -> {
                inputConnection.commitText(" ", 1)
                contextBuffer.append(" ")
                isWordBoundary = true
            }
            "return", "Go" -> {
                inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
                inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
                contextBuffer.append("\n")
                isWordBoundary = true
            }
            "☺" -> {
                inputConnection.commitText("😊", 1)
                contextBuffer.append("😊")
                isWordBoundary = true
            }
            else -> {
                inputConnection.commitText(keyText, 1)
                contextBuffer.append(keyText)
                if (!isSymbols && shiftState == ShiftState.ON) {
                    shiftState = ShiftState.OFF
                    updateShiftUI()
                }
                if (symbolChars.contains(keyText) || extraSymbolChars.contains(keyText)) {
                     isWordBoundary = true
                }
            }
        }
        
        if (contextBuffer.length > 1000) {
            contextBuffer.delete(0, contextBuffer.length - 1000)
        }

        triggerSuggestion(isWordBoundary)
    }

    private fun acceptSuggestion() {
        if (lastSuggestedCompletion.isNotEmpty()) {
            val extractedText = try {
                currentInputConnection?.getExtractedText(ExtractedTextRequest(), 0)
            } catch (e: Exception) {
                null
            }

            val totalLength = extractedText?.text?.length ?: 0
            if (totalLength > 0) {
                currentInputConnection?.deleteSurroundingText(totalLength, totalLength)
            }

            currentInputConnection?.commitText("$lastSuggestedCompletion ", 1)
            contextBuffer.clear()
            contextBuffer.append("$lastSuggestedCompletion ")

            lastSuggestedCompletion = ""
            lastTypedLength = 0
            tvSuggestion.text = "..."
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        suggestionRunnable?.let { suggestionHandler.removeCallbacks(it) }
        suggestionRunnable = null
        tts?.stop()
        tts?.shutdown()
        tts = null
        historyManager.disconnect()
    }

    private fun toggleEmojiView() {
        if (keyboardState == KeyboardState.EMOJI) {
            showKeyboardState(KeyboardState.MAIN)
        } else {
            showKeyboardState(KeyboardState.EMOJI)
        }
    }

    private fun showKeyboardState(state: KeyboardState) {
        keyboardState = state
        layoutQwerty.visibility = if (state == KeyboardState.MAIN) View.VISIBLE else View.GONE
        layoutEmoji.visibility = if (state == KeyboardState.EMOJI) View.VISIBLE else View.GONE
        emojiButton.text = if (state == KeyboardState.EMOJI) "ABC" else "☺"
    }

    private fun onAgentActionClick(actionId: String) {
        // Smart Action Lookup
        val smartAction = currentSmartActions.find { 
            try { it.getString("id") == actionId } catch (e: Exception) { false } 
        }

        if (smartAction != null) {
            val type = smartAction.optString("type", "")
            val label = smartAction.optString("label", actionId)
            
            android.util.Log.d("Typira", "Tapped Smart Action: $actionId Type: $type")
            
            if (type == "deep_link") {
                val payload = smartAction.optString("payload", "")
                try {
                    val intent = android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(payload))
                    intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    tvSuggestion.text = "Opening $label..."
                } catch (e: Exception) {
                    Toast.makeText(this, "Could not open: $label", Toast.LENGTH_SHORT).show()
                }
            } else if (type == "calendar_event") {
                 val payloadObj = smartAction.optJSONObject("payload")
                 if (payloadObj != null) {
                     handleNativeCalendarEvent(payloadObj)
                 }
            } else if (type == "prompt_trigger") {
                // Ensure payload is a string here, or handle as JsonObject convert to string if needed
                val payloadStr = smartAction.optString("payload", "") 
                val inputConnection = currentInputConnection
                val extractedText = inputConnection?.getExtractedText(ExtractedTextRequest(), 0)
                val fullContext = extractedText?.text?.toString() ?: ""
                
                historyManager.performAction(actionId, type, payloadStr, fullContext)
                tvSuggestion.text = "Typira is working on: $label..."
            }
            return
        }

        // Legacy/Fixed Action Hub
        Toast.makeText(this, "Agent: $actionId", Toast.LENGTH_SHORT).show()
        if (actionId == "Rewrite") {
            val currentText = currentInputConnection?.getExtractedText(ExtractedTextRequest(), 0)?.text?.toString() ?: ""
            if (currentText.isNotEmpty()) {
                requestNativeRewrite(currentText)
            }
            showKeyboardState(KeyboardState.MAIN)
        }
    }

    private fun handleNativeCalendarEvent(payload: JSONObject) {
        try {
            val title = payload.optString("title", "Reminder")
            val description = payload.optString("description", "")
            val startStr = payload.optString("start", "")
            val endStr = payload.optString("end", "")

            val startTime = if (startStr.isNotEmpty()) {
                java.time.ZonedDateTime.parse(startStr).toInstant().toEpochMilli()
            } else {
                System.currentTimeMillis()
            }

            val endTime = if (endStr.isNotEmpty()) {
                java.time.ZonedDateTime.parse(endStr).toInstant().toEpochMilli()
            } else {
                startTime + 3600000 // +1 hour
            }

            val intent = android.content.Intent(android.content.Intent.ACTION_INSERT).apply {
                data = android.provider.CalendarContract.Events.CONTENT_URI
                putExtra(android.provider.CalendarContract.Events.TITLE, title)
                putExtra(android.provider.CalendarContract.Events.DESCRIPTION, description)
                putExtra(android.provider.CalendarContract.EXTRA_EVENT_BEGIN_TIME, startTime)
                putExtra(android.provider.CalendarContract.EXTRA_EVENT_END_TIME, endTime)
                addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            
            try {
                startActivity(intent)
                tvSuggestion.text = "Setting up event: $title"
            } catch (e: Exception) {
                // If no app can handle ACTION_INSERT (rare, but happens if no calendar app installed)
                 Toast.makeText(this, "No Calendar app found. Please install one.", Toast.LENGTH_LONG).show()
                 
                 // Try to open generic calendar view
                 try {
                     val calIntent = android.content.Intent(android.content.Intent.ACTION_VIEW).apply {
                         data = android.net.Uri.parse("content://com.android.calendar/time/")
                         addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK)
                     }
                     startActivity(calIntent)
                 } catch (e2: Exception) {
                     // Fallback failed too
                 }
            }
        } catch (e: Exception) {
            android.util.Log.e("Typira", "Calendar Intent Error: ${e.message}")
            Toast.makeText(this, "Could not open calendar", Toast.LENGTH_SHORT).show()
        }
    }

    private fun requestNativeRewrite(text: String) {
        val prefs = getSharedPreferences("typira_memory", Context.MODE_PRIVATE)
        val memories = prefs.getStringSet("memories", setOf())?.joinToString(". ") ?: ""
        
        aiService.rewriteText(text, memories, object : AIService.GenericCallback {
            override fun onSuccess(result: String) {
                if (result.isNotEmpty()) {
                    currentInputConnection?.commitText("\n$result", 1)
                }
            }
            override fun onFailure(error: String) {
                android.util.Log.e("Typira", "Rewrite Error: $error")
            }
        })
    }

    private fun populateSuggestions(suggestion: String) {
        tvSuggestion.text = suggestion
    }

    private fun setupSpaceKeyTrackpad(spaceKey: View?) {
         spaceKey?.setOnTouchListener(object : View.OnTouchListener {
            private var lastX = 0f
            private var initialX = 0f
            private val MOVE_THRESHOLD = 20f 
            private var isSliding = false
            
            override fun onTouch(v: View, event: android.view.MotionEvent): Boolean {
                when (event.action) {
                    android.view.MotionEvent.ACTION_DOWN -> {
                        lastX = event.x
                        initialX = event.x
                        isSliding = false
                        return false 
                    }
                    android.view.MotionEvent.ACTION_MOVE -> {
                        val deltaX = event.x - lastX
                        if (!isSliding && Math.abs(event.x - initialX) > MOVE_THRESHOLD) {
                             isSliding = true
                        }
                        
                        if (isSliding) {
                             if (Math.abs(deltaX) > MOVE_THRESHOLD) {
                                  val direction = if (deltaX > 0) KeyEvent.KEYCODE_DPAD_RIGHT else KeyEvent.KEYCODE_DPAD_LEFT
                                  currentInputConnection?.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, direction))
                                  currentInputConnection?.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, direction))
                                  lastX = event.x
                             }
                             return true
                        }
                        return false
                    }
                    android.view.MotionEvent.ACTION_UP, android.view.MotionEvent.ACTION_CANCEL -> {
                        return isSliding
                    }
                }
                return false
            }
        })
    }
    
    private fun findLetterKeys(view: View) {
        if (view is Button) {
            val text = view.text.toString()
            if (text.length == 1 && Character.isLetter(text[0])) {
                letterButtons.add(view)
                view.setOnClickListener { v ->
                    val btn = v as Button
                    onKeyClick(btn.text.toString())
                }
            }
        } else if (view is android.view.ViewGroup) {
            val group = view as android.view.ViewGroup
            for (i in 0 until group.childCount) {
                findLetterKeys(group.getChildAt(i))
            }
        }
    }

    private fun handleShiftClick() {
        if (keyboardState == KeyboardState.EMOJI) toggleEmojiView()
        if (isSymbols) {
            isMoreSymbols = !isMoreSymbols
            if (isMoreSymbols) {
                 shiftText.text = "123" 
            } else {
                 shiftText.text = "#+="
            }
            updateKeys()
            return
        }
    
        val currentTime = System.currentTimeMillis()
        if (shiftState == ShiftState.OFF) {
            if (currentTime - lastShiftPressTime < DOUBLE_TAP_TIMEOUT) {
                 shiftState = ShiftState.LOCKED
            } else {
                 shiftState = ShiftState.ON
            }
        } else if (shiftState == ShiftState.ON) {
            if (currentTime - lastShiftPressTime < DOUBLE_TAP_TIMEOUT) {
                shiftState = ShiftState.LOCKED
            } else {
                shiftState = ShiftState.OFF
            }
        } else {
            shiftState = ShiftState.OFF
        }
        
        lastShiftPressTime = currentTime
        updateShiftUI()
    }
    
    private fun toggleSymbols() {
        if (keyboardState == KeyboardState.EMOJI) toggleEmojiView()
        isSymbols = !isSymbols
        isMoreSymbols = false
        
        if (isSymbols) {
            modeButton.text = "ABC"
            shiftIcon.visibility = View.GONE
            shiftText.visibility = View.VISIBLE
            shiftText.text = "#+="
        } else {
            modeButton.text = "?123"
            updateShiftUI()
        }
        updateKeys()
    }

    private fun updateShiftUI() {
        if (isSymbols) return 
        
        shiftIcon.visibility = View.VISIBLE
        shiftText.visibility = View.GONE

        when (shiftState) {
            ShiftState.OFF -> {
                shiftIcon.setBackgroundResource(R.drawable.key_background_special)
                shiftIcon.setImageResource(R.drawable.ic_shift)
            }
            ShiftState.ON -> {
                shiftIcon.setBackgroundResource(R.drawable.key_background)
                shiftIcon.setImageResource(R.drawable.ic_shift_fill)
            }
            ShiftState.LOCKED -> {
                shiftIcon.setBackgroundResource(R.drawable.key_background)
                shiftIcon.setImageResource(R.drawable.ic_shift_lock)
            }
        }
        updateKeys()
    }

    private fun updateKeys() {
        if (letterButtons.size != 26) return

        for ((index, btn) in letterButtons.withIndex()) {
            if (isSymbols) {
                if (isMoreSymbols) {
                     val char = extraSymbolChars.getOrNull(index) ?: ' '
                     btn.text = char.toString()
                } else {
                     val char = symbolChars.getOrNull(index) ?: ' '
                     btn.text = char.toString()
                }
            } else {
                val char = qwertyChars.getOrNull(index) ?: ' '
                if (shiftState != ShiftState.OFF) {
                    btn.text = char.uppercaseChar().toString()
                } else {
                    btn.text = char.toString()
                }
            }
        }
    }

    private fun triggerSuggestion(isWordBoundary: Boolean) {
        suggestionRunnable?.let { suggestionHandler.removeCallbacks(it) }
        val delay = if (isWordBoundary) 600L else 1500L
        
        suggestionRunnable = Runnable {
            val text = contextBuffer.toString()
            if (text.trim().length >= 3) {
                 fetchAISuggestion(text)
            } else {
                 // Removed tvSuggestion.text = "Typira" to avoid overwriting Thought Stream
            }
        }
        
        suggestionHandler.postDelayed(suggestionRunnable!!, delay)
    }
    
    private fun fetchAISuggestion(currentText: String) {
        if (currentText.isBlank()) return
        
        tvSuggestion.alpha = 0.5f

        val prefs = getSharedPreferences("typira_memory", Context.MODE_PRIVATE)
        val memories = prefs.getStringSet("memories", setOf())?.joinToString(". ") ?: ""

        aiService.fetchSuggestion(currentText, memories, object : AIService.SuggestionCallback {
            override fun onSuccess(suggestion: String) {
                tvSuggestion.alpha = 1.0f
                if (suggestion.isEmpty()) {
                    lastSuggestedCompletion = ""
                    tvSuggestion.text = "..."
                } else {
                    lastSuggestedCompletion = suggestion
                    tvSuggestion.text = "$suggestion (Tap to insert)"
                }
            }

            override fun onFailure(error: String) {
               android.util.Log.e("Typira", "Suggestion Failed: $error")
               tvSuggestion.alpha = 1.0f
            }

            override fun onCancelled() {
                // Ignore
            }
        })
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        contextBuffer.setLength(0) 
        
        shiftState = ShiftState.OFF
        isSymbols = false
        isMoreSymbols = false
        keyboardState = KeyboardState.MAIN
        if (this::layoutQwerty.isInitialized) layoutQwerty.visibility = View.VISIBLE
        if (this::layoutEmoji.isInitialized) layoutEmoji.visibility = View.GONE
        if (this::emojiButton.isInitialized) emojiButton.text = "☺"
        if (this::modeButton.isInitialized) modeButton.text = "?123"
        if (this::shiftIcon.isInitialized) updateShiftUI()
        
        // Initial Full Context Ingestion
        try {
            val fullText = currentInputConnection?.getExtractedText(ExtractedTextRequest(), 0)?.text?.toString() ?: ""
            historyManager.sendFullContext(fullText, info)
        } catch (e: Exception) {
            android.util.Log.e("Typira", "Failed to grab initial context: ${e.message}")
        }
    }

    private fun handleRememberAction() {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clipData = clipboard.primaryClip
        if (clipData != null && clipData.itemCount > 0) {
            val text = clipData.getItemAt(0).text?.toString()
            if (!text.isNullOrBlank()) {
                if (text.length < 3) {
                    Toast.makeText(this, "Text too short to remember", Toast.LENGTH_SHORT).show()
                    return
                }
                
                aiService.syncMemory(text)
                saveMemory(text) 
                Toast.makeText(this, "🧠 Memory Saved", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun saveMemory(text: String) {
        val prefs = getSharedPreferences("typira_memory", Context.MODE_PRIVATE)
        val memories = prefs.getStringSet("memories", mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        memories.add(text)
        prefs.edit().putStringSet("memories", memories).apply()
    }

    private fun handleMicAction() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(this, "Microphone permission required", Toast.LENGTH_LONG).show()
            return
        }

        if (audioService.isRecording) {
            audioService.stopRecording(
                onStop = { path ->
                    Toast.makeText(this, "🎙️ Processing...", Toast.LENGTH_SHORT).show()
                    aiService.uploadAudio(path, object : AIService.GenericCallback {
                        override fun onSuccess(transcript: String) {
                            if (transcript.isNotEmpty()) {
                                currentInputConnection?.commitText(transcript + " ", 1)
                            }
                        }
                        override fun onFailure(error: String) {
                            Toast.makeText(this@TypiraInputMethodService, "STT Failed: $error", Toast.LENGTH_SHORT).show()
                        }
                    })
                },
                onError = { error -> Toast.makeText(this, error, Toast.LENGTH_SHORT).show() }
            )
        } else {
            audioService.startRecording(
                cacheDir,
                onStart = { Toast.makeText(this, "🎙️ Listening...", Toast.LENGTH_SHORT).show() },
                onError = { error -> Toast.makeText(this, "Recording failed: $error", Toast.LENGTH_SHORT).show() }
            )
        }
    }
}
