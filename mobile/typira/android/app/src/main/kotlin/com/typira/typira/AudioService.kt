package com.typira.typira

import android.media.MediaRecorder
import java.io.File

/**
 * AudioService
 * Handles microphone recording interactions.
 */
class AudioService {
    
    private var mediaRecorder: MediaRecorder? = null
    var isRecording = false
    var currentAudioPath: String? = null

    fun startRecording(cacheDir: File, onStart: (String) -> Unit, onError: (String) -> Unit) {
        try {
            val audioFile = File.createTempFile("typira_voice_", ".m4a", cacheDir)
            currentAudioPath = audioFile.absolutePath

            mediaRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setOutputFile(currentAudioPath)
                prepare()
                start()
            }

            isRecording = true
            onStart(audioFile.absolutePath)
        } catch (e: Exception) {
            isRecording = false
            onError(e.message ?: "Unknown recording error")
        }
    }

    fun stopRecording(onStop: (String) -> Unit, onError: (String) -> Unit) {
        try {
            isRecording = false
            mediaRecorder?.stop()
            mediaRecorder?.release()
            mediaRecorder = null
            
            val path = currentAudioPath
            if (path != null) {
                onStop(path)
            } else {
                onError("No audio file found")
            }
        } catch (e: Exception) {
            onError(e.message ?: "Error stopping recording")
        }
    }
}
