package com.paulingalls.realtimeaudio

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.os.Handler
import android.os.Looper
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

class RealtimeAudioVADRecorderView(
    context: Context,
    appContext: AppContext
) : ExpoView(context, appContext),
    RealtimeAudioVoiceDelegate {
    private val onVoiceCaptured by EventDispatcher<Map<String, String>>()
    private val onVoiceStarted by EventDispatcher()
    private val onVoiceEnded by EventDispatcher()
    private var audioRecorder: RealtimeAudioVADRecorder? = null
    private var visualization: AudioVisualization = LinearWaveformVisualizer()
    private var audioChunks: ArrayList<FloatArray> = ArrayList()
    private val handler = Handler(Looper.getMainLooper())
    private var isListening = false
    private var isEchoCancellationEnabled = false
    private var channelCount: Int = 1
    private var sampleRate: Int = 0
    private var modelPath: String = ""
    private var mainColor: Int = Color.BLUE

    init {
        setWillNotDraw(false)
        visualization.setColor(mainColor)
    }

    fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioRecorder?.release()
        audioRecorder = RealtimeAudioVADRecorder(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioVADRecorderView
            isEchoCancellationEnabled = this@RealtimeAudioVADRecorderView.isEchoCancellationEnabled
            modelPath = this@RealtimeAudioVADRecorderView.modelPath
        }
        channelCount = channelConfig
        this.sampleRate = sampleRate
    }

    fun setVisualizationColor(color: Int) {
        mainColor = color
        visualization.setColor(color)
        invalidate()
    }

    fun setVisualizer(visualization: BaseVisualization) {
        this.visualization = visualization
        this.visualization.setColor(mainColor)
        invalidate()
    }

    fun startListening() {
        isListening = true
        audioRecorder?.modelPath = modelPath
        audioRecorder?.startListening()
        postInvalidate()
    }

    fun stopListening() {
        isListening = false
        audioRecorder?.stopListening()
        postInvalidate()
    }

    override fun audioStringReady(base64Audio: String) {
        onVoiceCaptured(mapOf("audioBuffer" to base64Audio))
    }

    override fun voiceBufferReady(buffer: FloatArray) {
        val sampleCount = width / 2
        val newChunks = visualization.getSampleChunksFromAudio(buffer, channelCount, sampleCount)
        val chunkDuration =
            ((buffer.size.toFloat() * 1000.0) / (sampleRate.toFloat() * newChunks.size.toFloat())).toLong()
        var timeOfNextChunk = 0L
        audioChunks.addAll(newChunks)
        for (chunkIndex in 0 until newChunks.size) {
            handler.postDelayed({
                postInvalidateOnAnimation()
            }, timeOfNextChunk)
            timeOfNextChunk += chunkDuration
        }
    }

    override fun voiceStarted() {
        onVoiceStarted(mapOf())
    }

    override fun voiceStopped() {
        visualization.updateData(FloatArray(0))
        audioChunks.clear()
        onVoiceEnded(mapOf())
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (isListening && audioChunks.size > 0) {
            val chunk = audioChunks.removeAt(0)
            visualization.updateData(chunk)
            visualization.draw(canvas, width.toFloat(), height.toFloat())
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        audioRecorder?.release()
    }

    fun setEchoCancellationEnabled(echoCancellationEnabled: Boolean) {
        isEchoCancellationEnabled = echoCancellationEnabled
        audioRecorder?.isEchoCancellationEnabled = echoCancellationEnabled
    }

    fun setModelPath(modelPath: String) {
        this.modelPath = modelPath
    }
}