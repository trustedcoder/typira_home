package com.typira.typira

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.ExtractedTextRequest
import io.socket.client.IO
import io.socket.client.Socket
import org.json.JSONObject
import java.net.URISyntaxException

class TypingHistoryManager(private val context: Context, private val onThoughtUpdate: (String) -> Unit) {

    private var socket: Socket? = null
    private val textBuffer = StringBuilder()
    private val handler = Handler(Looper.getMainLooper())
    private var lastEditorInfo: EditorInfo? = null
    private var jwtToken: String? = null

    private val syncRunnable = Runnable { syncHistory() }
    private val DEBOUNCE_DELAY_MS = 2000L

    init {
        loadJwtToken()
        setupSocket()
    }

    private fun loadJwtToken() {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rawToken = prefs.getString("flutter.auth", null)
        if (rawToken != null) {
            jwtToken = rawToken.removePrefix("\"").removeSuffix("\"")
            Log.d("TypiraHistory", "JWT Token loaded for Socket")
        }
    }

    private fun setupSocket() {
        try {
            Log.d("TypiraSocket", "Attempting to connect to http://10.0.2.2:7009")
            val opts = IO.Options()
            opts.forceNew = true
            opts.reconnection = true
            socket = IO.socket("http://10.0.2.2:7009", opts)

            socket?.on(Socket.EVENT_CONNECT) {
                Log.d("TypiraSocket", "SUCCESS: Connected to Backend")
            }

            socket?.on(Socket.EVENT_CONNECT_ERROR) { args ->
                Log.e("TypiraSocket", "CONNECTION ERROR: ${args.getOrNull(0)}")
            }

            socket?.on("thought_update") { args ->
                try {
                    val data = args[0] as JSONObject
                    val thought = data.getString("text")
                    Log.d("TypiraSocket", "Received thought: $thought")
                    handler.post { onThoughtUpdate("💭 $thought") }
                } catch (e: Exception) {
                    Log.e("TypiraSocket", "Error parsing thought_update: ${e.message}")
                }
            }

            socket?.on("suggestion_ready") { args ->
                try {
                    val data = args[0] as JSONObject
                    val thought = data.getString("thought")
                    Log.d("TypiraSocket", "Received suggestion: $thought")
                    // Use a different icon for suggestions
                    handler.post { onThoughtUpdate("💡 $thought") }
                } catch (e: Exception) {
                    Log.e("TypiraSocket", "Error parsing suggestion_ready: ${e.message}")
                }
            }

            socket?.on(Socket.EVENT_DISCONNECT) {
                Log.d("TypiraSocket", "Socket Disconnected")
            }

            socket?.connect()
        } catch (e: URISyntaxException) {
            Log.e("TypiraSocket", "URL Error: ${e.message}")
        }
    }

    fun onTextTyped(text: CharSequence, editorInfo: EditorInfo?) {
        this.lastEditorInfo = editorInfo
        if (isPasswordField(editorInfo)) return

        textBuffer.append(text)
        handler.removeCallbacks(syncRunnable)
        handler.postDelayed(syncRunnable, DEBOUNCE_DELAY_MS)
        
        if (textBuffer.length > 300) {
            handler.removeCallbacks(syncRunnable)
            syncHistory()
        }
    }

    fun sendFullContext(fullText: String, editorInfo: EditorInfo?) {
        this.lastEditorInfo = editorInfo
        if (isPasswordField(editorInfo)) return
        
        if (socket?.connected() != true) {
            socket?.connect()
        }

        val json = JSONObject()
        json.put("token", jwtToken)
        json.put("text", fullText)
        json.put("is_full_context", true) // Tag it so backend knows
        json.put("app_context", editorInfo?.packageName ?: "unknown")

        socket?.emit("analyze", json)
        Log.d("TypiraSocket", "Sent Full Context: ${fullText.length} chars")
    }

    private fun isPasswordField(info: EditorInfo?): Boolean {
        if (info == null) return false
        val inputType = info.inputType
        val variation = inputType and EditorInfo.TYPE_MASK_VARIATION
        return (variation == EditorInfo.TYPE_TEXT_VARIATION_PASSWORD) ||
               (variation == EditorInfo.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD)
    }

    private fun syncHistory() {
        // We use the buffer to know IF we should sync, but we send the FULL context for analysis
        if (textBuffer.isEmpty()) return
        if (socket?.connected() != true) {
            socket?.connect()
            if (socket?.connected() != true) return 
        }

        val contentToSend = textBuffer.toString()
        textBuffer.clear()

        // Fetch Full Context
        // Note: For privacy, sendFullContext already does a password check.
        // We'll use a helper to get the full text if possible.
        val inputConnection = (context as TypiraInputMethodService).currentInputConnection
        val fullText = inputConnection?.getExtractedText(ExtractedTextRequest(), 0)?.text?.toString() ?: contentToSend

        val json = JSONObject()
        json.put("token", jwtToken)
        json.put("text", fullText) // Send full content for best AI results
        json.put("incremental_delta", contentToSend) // Keep delta for history if needed
        json.put("is_full_context", true)
        json.put("app_context", lastEditorInfo?.packageName ?: "unknown")

        socket?.emit("analyze", json)
        Log.d("TypiraSocket", "Synced Full Context (${fullText.length} chars) to Backend")
    }

    fun disconnect() {
        socket?.disconnect()
    }
}
