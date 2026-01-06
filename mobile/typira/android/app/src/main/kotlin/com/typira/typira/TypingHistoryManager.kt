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

class TypingHistoryManager(
    private val context: Context, 
    private val onThoughtUpdate: (String) -> Unit,
    private val onActionsReceived: (org.json.JSONArray) -> Unit
) {

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
                    val actions = data.optJSONArray("actions") ?: org.json.JSONArray()
                    
                    Log.d("TypiraSocket", "Received suggestion: $thought with ${actions.length()} actions")
                    
                    handler.post { 
                        onThoughtUpdate("💡 $thought")
                        onActionsReceived(actions)
                    }
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

        val cleanFullText = scrubPII(fullText)

        val json = JSONObject()
        json.put("token", jwtToken)
        json.put("text", cleanFullText)
        json.put("is_full_context", true) // Tag it so backend knows
        json.put("app_context", editorInfo?.packageName ?: "unknown")

        socket?.emit("analyze", json)
        Log.d("TypiraSocket", "Sent Scrubbed Full Context: ${cleanFullText.length} chars")
    }

    private fun isPasswordField(info: EditorInfo?): Boolean {
        if (info == null) return false
        val inputType = info.inputType
        val variation = inputType and EditorInfo.TYPE_MASK_VARIATION
        return (variation == EditorInfo.TYPE_TEXT_VARIATION_PASSWORD) ||
               (variation == EditorInfo.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD)
    }

    private fun scrubPII(text: String): String {
        var scrubbed = text
        
        // Redact Email
        val emailPattern = "[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\\.[a-zA-Z0-9-.]+"
        scrubbed = scrubbed.replace(Regex(emailPattern), "[EMAIL]")
        
        // Redact Credit Card
        val ccPattern = "\\b(?:\\d[ -]*?){13,16}\\b"
        scrubbed = scrubbed.replace(Regex(ccPattern), "[CREDIT_CARD]")
        
        // Redact PIN (4-6 digits)
        val pinPattern = "\\b\\d{4,6}\\b"
        scrubbed = scrubbed.replace(Regex(pinPattern), "[SENSITIVE_CODE]")
        
        return scrubbed
    }

    private fun syncHistory() {
        if (textBuffer.isEmpty()) return
        if (socket?.connected() != true) {
            socket?.connect()
            if (socket?.connected() != true) return 
        }

        val contentToSend = textBuffer.toString()
        textBuffer.clear()

        val inputConnection = (context as TypiraInputMethodService).currentInputConnection
        val fullText = inputConnection?.getExtractedText(ExtractedTextRequest(), 0)?.text?.toString() ?: contentToSend

        // Client-side PII scrubbing
        val cleanFullText = scrubPII(fullText)
        val cleanDelta = scrubPII(contentToSend)

        val json = JSONObject()
        json.put("token", jwtToken)
        json.put("text", cleanFullText)
        json.put("incremental_delta", cleanDelta)
        json.put("is_full_context", true)
        json.put("app_context", lastEditorInfo?.packageName ?: "unknown")

        socket?.emit("analyze", json)
        Log.d("TypiraSocket", "Synced Scrubbed Context (${cleanFullText.length} chars) to Backend")
    }

    fun disconnect() {
        socket?.disconnect()
    }
}
