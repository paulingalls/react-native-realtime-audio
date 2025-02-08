package com.paulingalls.realtimeaudio

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.media.AudioFormat
import android.os.Handler
import android.os.Looper
import convertByteArrayOfShortsToFloatArray
import convertByteArrayToFloatArray
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

class RealtimeAudioRecorderView(
    context: Context,
    appContext: AppContext
) : BaseAudioView(context, appContext),
    RealtimeAudioBufferDelegate {
    private val onAudioCaptured by EventDispatcher<Map<String, String>>()
    private val onCaptureComplete by EventDispatcher()
    private var audioRecorder: RealtimeAudioRecorder? = null
    private var isEchoCancellationEnabled = false

    override fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioRecorder?.release()
        audioRecorder = RealtimeAudioRecorder(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioRecorderView
            isEchoCancellationEnabled = this@RealtimeAudioRecorderView.isEchoCancellationEnabled
        }
        super.setAudioFormat(sampleRate, channelConfig, audioFormat)
    }

    fun setEchoCancellationEnabled(echoCancellationEnabled: Boolean) {
        isEchoCancellationEnabled = echoCancellationEnabled
        audioRecorder?.isEchoCancellationEnabled = echoCancellationEnabled
    }

    fun startRecording() {
        running = true
        audioRecorder?.startRecording()
        postInvalidate()
    }

    fun stopRecording() {
        running = false
        audioRecorder?.stopRecording()
    }

    override fun audioStringReady(base64Audio: String) {
        onAudioCaptured(mapOf("audioBuffer" to base64Audio))
    }

    override fun bufferReady(buffer: ByteArray) {
        val floatArray: FloatArray
        if (audioFormat == AudioFormat.ENCODING_PCM_16BIT) {
            floatArray = convertByteArrayOfShortsToFloatArray(buffer)
        } else {
            floatArray = convertByteArrayToFloatArray(buffer)
        }
        scheduleChunks(floatArray)
    }

    override fun captureComplete() {
        onCaptureComplete(mapOf())

        handler.postDelayed({
            visualization.updateData(FloatArray(0))
            audioChunks.clear()
            chunkRenderTimeInMillis = 0
            postInvalidate()
        }, 300)
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        audioRecorder?.release()
    }
}