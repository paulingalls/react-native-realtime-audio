package com.paulingalls.realtimeaudio

import android.content.Context
import android.graphics.Canvas
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
    private var audioRecorder: RealtimeAudioRecorder? = null
    private var visualization: AudioVisualization = WaveformVisualization()
    private var isRecording = false

    init {
        setWillNotDraw(false)
    }

    fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioRecorder?.release()
        audioRecorder = RealtimeAudioRecorder(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioRecorderView
        }
    }

    fun setVisualizationColor(color: Int) {
        visualization.setColor(color)
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
        val floatArray = convertByteArrayToFloatArray(buffer)
        visualization.updateData(floatArray)
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (isRecording) {
            visualization.draw(canvas, width.toFloat(), height.toFloat())
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        val width = resolveSize(200, widthMeasureSpec)
        val height = resolveSize(100, heightMeasureSpec)
        setMeasuredDimension(width, height)
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        audioRecorder?.release()
    }

}