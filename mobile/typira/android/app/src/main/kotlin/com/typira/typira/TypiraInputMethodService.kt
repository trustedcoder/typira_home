package com.typira.typira

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.ImageButton
import android.widget.LinearLayout
import android.view.KeyEvent
import java.util.Locale

class TypiraInputMethodService : InputMethodService() {

    // Logic for Caps Lock
    private enum class ShiftState {
        OFF,
        ON,
        LOCKED
    }

    private var shiftState = ShiftState.OFF
    private var lastShiftPressTime: Long = 0
    private val DOUBLE_TAP_TIMEOUT = 300L // ms

    private val letterButtons = mutableListOf<Button>()
    private lateinit var shiftButton: ImageButton

    override fun onCreateInputView(): View {
        val view = layoutInflater.inflate(R.layout.keyboard_view, null)
        setupKeyListeners(view)
        return view
    }

    private fun setupKeyListeners(rootView: View) {
        val backspace = rootView.findViewById<ImageButton>(R.id.key_backspace)
        backspace?.setOnClickListener { onKeyClick("⌫") }

        shiftButton = rootView.findViewById<ImageButton>(R.id.key_shift)
        shiftButton.setOnClickListener { handleShiftClick() }

        val emoji = rootView.findViewById<ImageButton>(R.id.key_emoji)
        emoji?.setOnClickListener { onKeyClick("☺") }

        val enter = rootView.findViewById<Button>(R.id.key_enter)
        enter?.setOnClickListener { onKeyClick("return") }
        
        val mode = rootView.findViewById<Button>(R.id.key_mode)
        mode?.setOnClickListener { onKeyClick("?123") }

        val space = rootView.findViewById<Button>(R.id.key_space)
        space?.setOnClickListener { onKeyClick("space") }

        findLetterKeys(rootView)
        
        updateShiftUI() // Initial State
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
        val currentTime = System.currentTimeMillis()
        
        if (shiftState == ShiftState.OFF) {
            // OFF -> ON
            // Check for double tap
            if (currentTime - lastShiftPressTime < DOUBLE_TAP_TIMEOUT) {
                 shiftState = ShiftState.LOCKED
            } else {
                 shiftState = ShiftState.ON
            }
        } else if (shiftState == ShiftState.ON) {
            // ON -> Tap -> OFF (or Locked if fast enough double tap relative to first, but usually toggle)
            // If user taps ON quickly after turning it ON, they might want LOCK.
            if (currentTime - lastShiftPressTime < DOUBLE_TAP_TIMEOUT) {
                shiftState = ShiftState.LOCKED
            } else {
                shiftState = ShiftState.OFF
            }
        } else if (shiftState == ShiftState.LOCKED) {
            // LOCKED -> Tap -> OFF
            shiftState = ShiftState.OFF
        }
        
        lastShiftPressTime = currentTime
        updateShiftUI()
    }

    private fun updateShiftUI() {
        when (shiftState) {
            ShiftState.OFF -> {
                shiftButton.setImageResource(R.drawable.ic_shift)
                shiftButton.setBackgroundResource(R.drawable.key_background_special)
                updateLetters(false)
            }
            ShiftState.ON -> {
                shiftButton.setImageResource(R.drawable.ic_shift_fill)
                shiftButton.setBackgroundResource(R.drawable.key_background) // Highlighted
                updateLetters(true)
            }
            ShiftState.LOCKED -> {
                shiftButton.setImageResource(R.drawable.ic_shift_lock)
                shiftButton.setBackgroundResource(R.drawable.key_background) // Highlighted
                updateLetters(true)
            }
        }
    }

    private fun updateLetters(upper: Boolean) {
        for (btn in letterButtons) {
            val currentText = btn.text.toString()
            btn.text = if (upper) {
                currentText.uppercase(Locale.getDefault())
            } else {
                currentText.lowercase(Locale.getDefault())
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
            "?123", "\\?123" -> { /* TODO */ }
            else -> {
                // Letter
                inputConnection.commitText(keyText, 1)
                
                // Auto-disable if just ON (not LOCKED)
                if (shiftState == ShiftState.ON) {
                    shiftState = ShiftState.OFF
                    updateShiftUI()
                }
            }
        }
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        // Reset shift on new input
        shiftState = ShiftState.OFF
        updateShiftUI()
    }
}
