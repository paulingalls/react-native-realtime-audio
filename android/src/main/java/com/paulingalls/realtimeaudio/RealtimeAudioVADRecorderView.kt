package com.paulingalls.realtimeaudio

import android.content.Context
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher

class RealtimeAudioVADRecorderView(
    context: Context,
    appContext: AppContext
) : BaseAudioView(context, appContext),
    RealtimeAudioVoiceDelegate {
    private val onVoiceCaptured by EventDispatcher<Map<String, String>>()
    private val onVoiceStarted by EventDispatcher()
    private val onVoiceEnded by EventDispatcher()
    private var audioRecorder: RealtimeAudioVADRecorder? = null
    private var isEchoCancellationEnabled = false
    private var modelPath: String = ""
    private var voiceActive: Boolean = false

    override fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioRecorder?.release()
        audioRecorder = RealtimeAudioVADRecorder(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioVADRecorderView
            isEchoCancellationEnabled = this@RealtimeAudioVADRecorderView.isEchoCancellationEnabled
            modelPath = this@RealtimeAudioVADRecorderView.modelPath
        }
        super.setAudioFormat(sampleRate, channelConfig, audioFormat)
    }

    fun setEchoCancellationEnabled(echoCancellationEnabled: Boolean) {
        isEchoCancellationEnabled = echoCancellationEnabled
        audioRecorder?.isEchoCancellationEnabled = echoCancellationEnabled
    }

    fun setModelPath(modelPath: String) {
        this.modelPath = modelPath
    }

    fun startListening() {
        running = true
        audioRecorder?.modelPath = modelPath
        audioRecorder?.startListening()
        postInvalidate()
    }

    fun stopListening() {
        running = false
        audioRecorder?.stopListening()
    }

    override fun audioStringReady(base64Audio: String) {
        onVoiceCaptured(mapOf("audioBuffer" to base64Audio))
    }

    override fun voiceBufferReady(buffer: FloatArray) {
        if (!voiceActive) {
            return
        }
        scheduleChunks(buffer)
    }

    override fun voiceStarted() {
        voiceActive = true
        onVoiceStarted(mapOf())
    }

    override fun voiceStopped() {
        onVoiceEnded(mapOf())
        voiceActive = false
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