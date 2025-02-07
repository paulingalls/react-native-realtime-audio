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
) : ExpoView(context, appContext),
    RealtimeAudioBufferDelegate {
    private val onAudioCaptured by EventDispatcher<Map<String, String>>()
    private val onCaptureComplete by EventDispatcher()
    private var audioRecorder: RealtimeAudioRecorder? = null
    private var visualization: AudioVisualization = LinearWaveformVisualizer()
    private var audioChunks: ArrayList<FloatArray> = ArrayList()
    private val handler = Handler(Looper.getMainLooper())
    private var isRecording = false
    private var isEchoCancellationEnabled = false
    private var channelCount: Int = 1
    private var sampleRate: Int = 0
    private var audioFormat: Int = 0
    private var mainColor: Int = Color.BLUE

    init {
        setWillNotDraw(false)
        visualization.setColor(mainColor)
    }

    fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioRecorder?.release()
        audioRecorder = RealtimeAudioRecorder(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioRecorderView
            isEchoCancellationEnabled = this@RealtimeAudioRecorderView.isEchoCancellationEnabled
        }
        channelCount = channelConfig
        this.sampleRate = sampleRate
        this.audioFormat = audioFormat
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

    fun startRecording() {
        isRecording = true
        audioRecorder?.startRecording()
        postInvalidate()
    }

    fun stopRecording() {
        isRecording = false
        audioRecorder?.stopRecording()
        postInvalidate()
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
        val sampleCount = width / 2
        val newChunks = visualization.getSampleChunksFromAudio(floatArray, channelCount, sampleCount)
        val chunkDuration =
            ((floatArray.size.toFloat() * 1000.0) / (sampleRate.toFloat() * newChunks.size.toFloat())).toLong()
        var timeOfNextChunk = 0L
        audioChunks.addAll(newChunks)
        for (chunkIndex in 0 until newChunks.size) {
            handler.postDelayed({
                postInvalidateOnAnimation()
            }, timeOfNextChunk)
            timeOfNextChunk += chunkDuration
        }
    }

    override fun captureComplete() {
        visualization.updateData(FloatArray(0))
        audioChunks.clear()
        onCaptureComplete(mapOf())
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (isRecording && audioChunks.size > 0) {
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

}