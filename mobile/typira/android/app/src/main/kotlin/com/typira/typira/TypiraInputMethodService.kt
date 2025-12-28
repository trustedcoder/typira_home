package com.typira.typira

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.MotionEvent
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.view.KeyEvent
import java.util.Locale

class TypiraInputMethodService : InputMethodService() {

    private enum class ShiftState {
        OFF,
        ON,
        LOCKED
    }

    private var shiftState = ShiftState.OFF
    private var lastShiftPressTime: Long = 0
    private val DOUBLE_TAP_TIMEOUT = 300L

    private var isSymbols = false
    private var isMoreSymbols = false

    private val letterButtons = mutableListOf<Button>()
    private val qwertyChars = "qwertyuiopasdfghjklzxcvbnm"
    // iOS Standard 123 Layout
    private val symbolChars = "1234567890-/:;()$&@\".,?!'  " 
    // iOS Standard #+= Layout
    private val extraSymbolChars = "[]{}#%^*+=_\\|~<>€£¥•.,?!'  "

    private lateinit var shiftButton: Button
    private lateinit var modeButton: Button
    private lateinit var emojiButton: Button
    private lateinit var layoutQwerty: View
    private lateinit var layoutEmoji: View
    private lateinit var gridEmoji: android.widget.GridLayout

    private var isEmojiView = false

    override fun onCreateInputView(): View {
        val view = layoutInflater.inflate(R.layout.keyboard_view, null)
        setupKeyListeners(view)
        return view
    }

    private fun setupKeyListeners(rootView: View) {
        layoutQwerty = rootView.findViewById(R.id.layout_qwerty)
        layoutEmoji = rootView.findViewById(R.id.layout_emoji)
        gridEmoji = rootView.findViewById(R.id.grid_emoji)

        // Now using Button for backspace
        val backspace = rootView.findViewById<Button>(R.id.key_backspace)
        backspace?.setOnClickListener { onKeyClick("⌫") }

        shiftButton = rootView.findViewById<Button>(R.id.key_shift)
        shiftButton.setOnClickListener { handleShiftClick() }

        emojiButton = rootView.findViewById<Button>(R.id.key_emoji)
        emojiButton.setOnClickListener { toggleEmojiView() }

        val enter = rootView.findViewById<Button>(R.id.key_enter)
        enter?.setOnClickListener { onKeyClick("return") }
        
        modeButton = rootView.findViewById<Button>(R.id.key_mode)
        modeButton.setOnClickListener { toggleSymbols() }

        val space = rootView.findViewById<Button>(R.id.key_space)
        space?.setOnClickListener { onKeyClick("space") }
        setupSpaceKeyTrackpad(space)

        letterButtons.clear()
        findLetterKeys(rootView)
        
        updateShiftUI() 
        populateEmojiGrid()
    }

    private fun toggleEmojiView() {
        isEmojiView = !isEmojiView
        if (isEmojiView) {
            layoutQwerty.visibility = View.GONE
            layoutEmoji.visibility = View.VISIBLE
            emojiButton.text = "ABC"
        } else {
            layoutQwerty.visibility = View.VISIBLE
            layoutEmoji.visibility = View.GONE
            emojiButton.text = "☺"
        }
    }

    private fun populateEmojiGrid() {
        val emojiGroups = listOf(
            listOf("😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰", "😘", "😗", "😙", "😚", "😋", "😛", "😝", "😜", "🤪", "🤨", "🧐", "🤓", "😎", "🤩", "🥳", "😏", "😒", "😞", "😔", "😟", "😕", "🙁", "☹️", "😣", "😖", "😫", "😩", "🥺", "😢", "😭", "😤", "😠", "😡", "🤬", "🤯", "😳", "🥵", "🥶", "😱", "😨", "😰", "😥", "😓", "🤗"),
            listOf("🤔", "🤭", "🤫", "🤥", "😶", "😐", "😑", "😬", "🙄", "😯", "😦", "😧", "😮", "😲", "🥱", "😴", "🤤", "😪", "😵", "🤐", "🥴", "🤢", "🤮", "🤧", "🥵", "🥶", "😷", "🤒", "🤕", "🤑", "🤠", "😈", "👿", "👹", "👺", "🤡", "💩", "👻", "💀", "☠️", "👽", "👾", "🤖", "🎃", "😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"),
            listOf("🤲", "👐", "🙌", "👏", "🤝", "👍", "👎", "👊", "✊", "🤛", "🤜", "🤞", "✌️", "🤟", "🤘", "👌", "👈", "👉", "👆", "👇", "☝️", "✋", "🤚", "🖐", "🖖", "👋", "🤙", "💪", "🖕", "✍️", "🙏", "💍", "💄", "💋", "👄", "👅", "👂", "👃", "👣", "👁", "👀", "🧠", "🗣", "👤", "👥"),
            listOf("🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐽", "🐸", "🐵", "🙈", "🙉", "🙊", "🐒", "🐔", "🐧", "🐦", "🐤", "🐣", "🐥", "🦆", "🦅", "🦉", "🦇", "🐺", "🐗", "🐴", "🦄", "🐝", "🐛", "🦋", "🐌", "🐞", "🐜", "🦟", "🦗", "🕷", "🕸", "🦂", "🐢", "🐍", "🦎", "🦖", "🦕", "🐙", "🦑", "🦐", "🦞", "🦀", "🐡", "🐠", "🐟", "🐬", "🐳", "🐋", "🦈", "🐊", "🐅", "🐆", "🦓", "🦍", "🦧", "🐘", "🦛", "🦏", "🐪", "🐫", "🦒", "🦘", "🐃", "🐂", "🐄", "🐎", "🐖", "🐏", "🐑", "🦙", "🐐", "🦌", "🐕", "🐩", "🦮", "🐕‍🦺", "🐈", "🐓", "🦃", "🦚", "🦜", "🦢", "🦩", "🕊", "🐇", "🦝", "🦨", "🦡", "🦦", "🦥", "🐁", "🐀", "🐿", "🦔", "🐾", "🐉", "🐲", "🌵", "🎄", "🌲", "🌳", "🌴", "🌱", "🌿", "☘️", "🍀", "🎍", "🎋", "🍃", "🍂", "🍁", "🍄", "🐚", "🌾", "💐", "🌷", "🌹", "🥀", "🌺", "🌸", "🌼", "🌻", "🌞", "🌝", "🌛", "🌜", "🌚", "🌕", "🌖", "🌗", "🌘", "🌑", "🌒", "🌓", "🌔", "🌙", "🌎", "🌍", "🌏", "🪐", "💫", "⭐️", "🌟", "✨", "⚡️", "☄️", "💥", "🔥", "🌪", "🌈", "☀️", "🌤", "⛅️", "🌥", "☁️", "🌦", "🌧", "⛈", "🌩", "🌨", "❄️", "☃️", "⛄️", "🌬", "💨", "💧", "💦", "☔️", "☂️", "🌊", "🌫")
        )

        gridEmoji.removeAllViews()
        for (group in emojiGroups) {
            for (emoji in group) {
                val btn = Button(this, null, 0, R.style.KeyboardKey)
                btn.text = emoji
                btn.textSize = 28f
                btn.setPadding(0, 0, 0, 0)
                val params = android.widget.GridLayout.LayoutParams()
                params.width = 0
                params.height = android.view.ViewGroup.LayoutParams.WRAP_CONTENT
                params.columnSpec = android.widget.GridLayout.spec(android.widget.GridLayout.UNDEFINED, 1f)
                btn.layoutParams = params
                btn.setOnClickListener { onKeyClick(emoji) }
                gridEmoji.addView(btn)
            }
            // Optional: spacer behavior would need a different view types in GridLayout or nested layouts.
            // For now, consistent grid is fine.
        }
    }

    private fun setupSpaceKeyTrackpad(spaceKey: View?) {
        spaceKey?.setOnTouchListener(object : View.OnTouchListener {
            private var lastX = 0f
            private var initialX = 0f
            private val MOVE_THRESHOLD = 20f 
            private var isSliding = false
            
            override fun onTouch(v: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        lastX = event.x
                        initialX = event.x
                        isSliding = false
                        // Don't consume yet, wait to see if it's a slide
                        return false 
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val deltaX = event.x - lastX
                        if (!isSliding && Math.abs(event.x - initialX) > MOVE_THRESHOLD) {
                             isSliding = true
                        }
                        
                        if (isSliding) {
                             if (Math.abs(deltaX) > MOVE_THRESHOLD) {
                                  // Move Cursor
                                  val direction = if (deltaX > 0) KeyEvent.KEYCODE_DPAD_RIGHT else KeyEvent.KEYCODE_DPAD_LEFT
                                  currentInputConnection?.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, direction))
                                  currentInputConnection?.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, direction))
                                  lastX = event.x
                             }
                             return true // Consume dragging
                        }
                        return false
                    }
                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                        // If it was a slide, we consumed it. If not, it falls through to click.
                        // But wait, if we return false on DOWN, the ClickListener usually fires on UP.
                        // We need to ensure we don't trigger click if we slid.
                        // Since we return true during MOVE if sliding, the sequence might be interrupted for Click?
                        // Actually, standard OnClickListener fires on UP if not consumed.
                        // If isSliding was true, we should return true here to prevent Click.
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
        if (isEmojiView) toggleEmojiView()
        // If in Symbols mode, this button acts as "More Symbols" (#+=)
        if (isSymbols) {
            isMoreSymbols = !isMoreSymbols
            if (isMoreSymbols) {
                 shiftButton.text = "123" // Go back to first layer
            } else {
                 shiftButton.text = "#+="
            }
            updateKeys()
            return
        }
    
        // Normal Shift Logic
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
        if (isEmojiView) toggleEmojiView()
        isSymbols = !isSymbols
        isMoreSymbols = false // Reset extra layer
        
        if (isSymbols) {
            modeButton.text = "ABC"
            // Show "#+=" on shift button
            shiftButton.background = null // clear special background
            shiftButton.setBackgroundResource(R.drawable.key_background_special)
            shiftButton.text = "#+="
            shiftButton.setCompoundDrawablesWithIntrinsicBounds(0, 0, 0, 0) // Clear icon
        } else {
            modeButton.text = "?123"
            updateShiftUI() // Restore shift icon
        }
        updateKeys()
    }

    private fun updateShiftUI() {
        // Only updates icons when NOT in symbols mode
        if (isSymbols) return 
        
        shiftButton.text = "" // Clear text
        when (shiftState) {
            ShiftState.OFF -> {
                shiftButton.setBackgroundResource(R.drawable.key_background_special)
                shiftButton.setCompoundDrawablesWithIntrinsicBounds(0, R.drawable.ic_shift, 0, 0)
            }
            ShiftState.ON -> {
                shiftButton.setBackgroundResource(R.drawable.key_background)
                shiftButton.setCompoundDrawablesWithIntrinsicBounds(0, R.drawable.ic_shift_fill, 0, 0)
            }
            ShiftState.LOCKED -> {
                shiftButton.setBackgroundResource(R.drawable.key_background)
                shiftButton.setCompoundDrawablesWithIntrinsicBounds(0, R.drawable.ic_shift_lock, 0, 0)
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

    private fun onKeyClick(keyText: String) {
        val inputConnection = currentInputConnection ?: return
        
        when (keyText) {
            "⌫" -> inputConnection.deleteSurroundingText(1, 0)
            "space" -> inputConnection.commitText(" ", 1)
            "return", "Go" -> {
                inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
                inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
            }
            "☺" -> inputConnection.commitText("😊", 1)
            else -> {
                inputConnection.commitText(keyText, 1)
                if (!isSymbols && shiftState == ShiftState.ON) {
                    shiftState = ShiftState.OFF
                    updateShiftUI()
                }
            }
        }
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        shiftState = ShiftState.OFF
        isSymbols = false
        isMoreSymbols = false
        isEmojiView = false
        if (this::layoutQwerty.isInitialized) layoutQwerty.visibility = View.VISIBLE
        if (this::layoutEmoji.isInitialized) layoutEmoji.visibility = View.GONE
        if (this::emojiButton.isInitialized) emojiButton.text = "☺"
        if (this::modeButton.isInitialized) modeButton.text = "?123"
        if (this::shiftButton.isInitialized) updateShiftUI()
    }
}
