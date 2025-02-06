package com.paulingalls.realtimeaudio

import android.annotation.SuppressLint
import android.media.AudioFormat
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
    private val sampleRate: Int,
    private val channelConfig: Int,
    private val audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
) : SharedObject() {
    var delegate: RealtimeAudioBufferDelegate? = null
    var isEchoCancellationEnabled = false

    private var audioRecord: AudioRecord? = null
    private var isRecording = false
    private var recordingJob: Job? = null
    private val recordingScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    private val bufferSize: Int =
        AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat) * 2

    fun startRecording() {
        if (isRecording) return

        try {
            initializeAudioRecord()
            audioRecord?.startRecording()
            isRecording = true
            startRecordingJob()
        } catch (e: Exception) {
            print("error starting to record $e")
        }
    }

    fun stopRecording() {
        isRecording = false
        recordingJob?.cancel()
        audioRecord?.apply {
            stop()
            release()
        }
        audioRecord = null
        delegate?.captureComplete()
    }

    @SuppressLint("MissingPermission")
    private fun initializeAudioRecord() {
        var source = MediaRecorder.AudioSource.MIC
        if (isEchoCancellationEnabled) {
            source = MediaRecorder.AudioSource.VOICE_COMMUNICATION
        }
        audioRecord = AudioRecord(
            source,
            sampleRate,
            channelConfig,
            audioFormat,
            bufferSize
        )
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
        recordingScope.cancel()
    }
}