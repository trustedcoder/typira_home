package com.typira.typira

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.LinearLayout

class TypiraInputMethodService : InputMethodService() {

    override fun onCreateInputView(): View {
        val view = layoutInflater.inflate(R.layout.keyboard_view, null)
        setupKeyListeners(view)
        return view
    }

    private fun setupKeyListeners(rootView: View) {
        val layout = rootView as? LinearLayout ?: return
        
        // Traverse all children to find Buttons
        // Note: Our layout has nested LinearLayouts for rows
        for (i in 0 until layout.childCount) {
            val child = layout.getChildAt(i)
            if (child is LinearLayout) {
                for (j in 0 until child.childCount) {
                    val key = child.getChildAt(j)
                    if (key is Button) {
                        key.setOnClickListener { onKeyClick(key.text.toString()) }
                    }
                }
            }
        }
    }

    private fun onKeyClick(keyText: String) {
        val inputConnection = currentInputConnection ?: return
        
        when (keyText) {
            "⌫" -> {
                inputConnection.deleteSurroundingText(1, 0)
            }
            "space" -> {
                inputConnection.commitText(" ", 1)
            }
            "return" -> {
                inputConnection.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_ENTER))
                inputConnection.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, android.view.KeyEvent.KEYCODE_ENTER))
            }
            "⇧" -> {
                // TODO: Implement Shift Logic
            }
            "123" -> {
                // TODO: Implement Symbols Layer
            }
            else -> {
                inputConnection.commitText(keyText, 1)
            }
        }
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
    }
}
