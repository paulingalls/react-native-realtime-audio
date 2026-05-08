package com.paulingalls.realtimeaudio

import android.annotation.SuppressLint
import android.content.Context
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Base64
import expo.modules.kotlin.sharedobjects.SharedObject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.nio.ByteBuffer

interface RealtimeAudioBufferDelegate {
    fun audioStringReady(base64Audio: String)
    fun bufferReady(buffer: ByteArray)
    fun captureComplete()
}

class RealtimeAudioRecorder(
    context: Context,
    private val sampleRate: Int,
    private val channelConfig: Int,
    private val audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
) : SharedObject() {
    var delegate: RealtimeAudioBufferDelegate? = null
    var isEchoCancellationEnabled = false

    private val audioManager =
        context.applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    private var audioRecord: AudioRecord? = null
    private var currentAudioSource: Int = -1
    private var savedAudioMode: Int = AudioManager.MODE_NORMAL
    private var didChangeAudioMode = false
    private var isRecording = false
    private var recordingJob: Job? = null
    private val recordingScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private val bufferSize: Int =
        AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat) * 2

    fun startRecording() {
        if (isRecording) return

        try {
            ensureAudioRecord()
            beginCommunicationModeIfNeeded()
            audioRecord?.startRecording()
            isRecording = true
            startRecordingJob()
        } catch (e: Exception) {
            print("error starting to record $e")
            endCommunicationModeIfNeeded()
        }
    }

    fun stopRecording() {
        if (isRecording) {
            delegate?.captureComplete()
        }
        isRecording = false
        recordingJob?.cancel()
        // Stop but keep the AudioRecord alive — re-creating an AudioRecord on the
        // VOICE_COMMUNICATION source costs 100-300ms of dead time per cycle. release()
        // happens in release().
        audioRecord?.stop()
        endCommunicationModeIfNeeded()
    }

    @SuppressLint("MissingPermission")
    private fun ensureAudioRecord() {
        val desiredSource = if (isEchoCancellationEnabled) {
            MediaRecorder.AudioSource.VOICE_COMMUNICATION
        } else {
            MediaRecorder.AudioSource.MIC
        }
        if (audioRecord != null && currentAudioSource == desiredSource) {
            return
        }
        audioRecord?.release()
        audioRecord = AudioRecord(
            desiredSource,
            sampleRate,
            channelConfig,
            audioFormat,
            bufferSize
        )
        currentAudioSource = desiredSource
    }

    private fun beginCommunicationModeIfNeeded() {
        if (!isEchoCancellationEnabled || didChangeAudioMode) return
        savedAudioMode = audioManager.mode
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        didChangeAudioMode = true
    }

    private fun endCommunicationModeIfNeeded() {
        if (!didChangeAudioMode) return
        audioManager.mode = savedAudioMode
        didChangeAudioMode = false
    }

    private fun startRecordingJob() {
        recordingJob = recordingScope.launch {
            val buffer = ByteBuffer.allocateDirect(bufferSize)
            val byteArray = ByteArray(bufferSize)

            while (isActive) {
                val readResult = audioRecord?.read(buffer, bufferSize) ?: -1

                if (readResult > 0) {
                    buffer.get(byteArray, 0, readResult)
                    delegate?.bufferReady(byteArray)
                    val base64Data = Base64.encodeToString(byteArray, 0, readResult, Base64.NO_WRAP)
                    delegate?.audioStringReady(base64Data)
                    buffer.clear()
                } else {
                    print("Error reading audio data: $readResult")
                }
            }
        }
    }

    fun release() {
        stopRecording()
        audioRecord?.release()
        audioRecord = null
        currentAudioSource = -1
        recordingScope.cancel()
    }
}
