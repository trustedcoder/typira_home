package com.typira.typira

import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.asRequestBody
import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.util.concurrent.TimeUnit
import android.os.Handler
import android.os.Looper

/**
 * AIService
 * Handles all network interactions with the backend (Suggestions, Rewrite, STT, Memory).
 */
class AIService {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    private val BASE_URL = "http://192.168.1.186:7009" // Using adb reverse
    private var currentSuggestionCall: Call? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    interface SuggestionCallback {
        fun onSuccess(suggestion: String)
        fun onFailure(error: String)
        fun onCancelled()
    }
    
    interface GenericCallback {
        fun onSuccess(result: String)
        fun onFailure(error: String)
    }

    fun cancelCurrentSuggestion() {
        currentSuggestionCall?.cancel()
    }

    fun fetchSuggestion(text: String, context: String, callback: SuggestionCallback) {
        val formBody = FormBody.Builder()
            .add("text", text)
            .add("context", context)
            .build()

        val request = Request.Builder()
            .url("$BASE_URL/suggest")
            .post(formBody)
            .build()

        currentSuggestionCall?.cancel()
        
        val call = client.newCall(request)
        currentSuggestionCall = call
        
        call.enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                if (call.isCanceled()) {
                    mainHandler.post { callback.onCancelled() }
                } else {
                    mainHandler.post { callback.onFailure(e.message ?: "Unknown error") }
                }
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!response.isSuccessful) {
                        mainHandler.post { callback.onFailure("HTTP ${response.code}") }
                        return
                    }
                    val body = response.body?.string() ?: ""
                    val suggestion = JSONObject(body).optString("suggestion", "")
                    mainHandler.post { callback.onSuccess(suggestion) }
                }
            }
        })
    }

    fun rewriteText(text: String, context: String, callback: GenericCallback) {
        val formBody = FormBody.Builder()
            .add("text", text)
            .add("context", context)
            .add("tone", "professional")
            .build()

        val request = Request.Builder()
            .url("$BASE_URL/rewrite")
            .post(formBody)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                mainHandler.post { callback.onFailure(e.message ?: "Detailed rewrite error") }
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!response.isSuccessful) {
                        mainHandler.post { callback.onFailure("HTTP ${response.code}") }
                        return
                    }
                    val body = response.body?.string() ?: ""
                    val rewritten = JSONObject(body).optString("rewritten_text", "")
                    mainHandler.post { callback.onSuccess(rewritten) }
                }
            }
        })
    }

    fun syncMemory(text: String) {
        val formBody = FormBody.Builder()
            .add("text", text)
            .build()

        val request = Request.Builder()
            .url("$BASE_URL/remember")
            .post(formBody)
            .build()

        // Fire and forget, but log errors
        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                android.util.Log.e("TypiraAI", "Memory sync error: ${e.message}")
            }
            override fun onResponse(call: Call, response: Response) {
                 // Success
            }
        })
    }

    fun uploadAudio(path: String, callback: GenericCallback) {
        val file = File(path)
        val requestBody = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("audio_file", file.name, file.asRequestBody("audio/m4a".toMediaType()))
            .build()

        val request = Request.Builder()
            .url("$BASE_URL/stt")
            .post(requestBody)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                mainHandler.post { callback.onFailure(e.message ?: "Upload failed") }
            }

            override fun onResponse(call: Call, response: Response) {
                response.use {
                    if (!response.isSuccessful) {
                        mainHandler.post { callback.onFailure("HTTP ${response.code}") }
                        return
                    }
                    val body = response.body?.string() ?: ""
                    val transcript = JSONObject(body).optString("transcription", "")
                    mainHandler.post { callback.onSuccess(transcript) }
                }
            }
        })
    }
}
