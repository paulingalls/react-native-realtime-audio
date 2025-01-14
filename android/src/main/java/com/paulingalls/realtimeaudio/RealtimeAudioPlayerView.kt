package com.paulingalls.realtimeaudio

import RealtimeAudioPlayer
import RealtimeAudioPlayerDelegate
import android.content.Context
import android.graphics.Canvas
import convertByteArrayToFloatArray
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

class RealtimeAudioPlayerView(
    context: Context, appContext: AppContext
) : ExpoView(context, appContext),
    RealtimeAudioPlayerDelegate {
    private val onPlaybackStarted by EventDispatcher()
    private val onPlaybackStopped by EventDispatcher()
    private var audioPlayer: RealtimeAudioPlayer? = null
    private var visualization: AudioVisualization = WaveformVisualization()
    private var isPlaying = false

    init {
        setWillNotDraw(false)
    }

    fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioPlayer?.release()
        audioPlayer = RealtimeAudioPlayer(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioPlayerView
        }
    }

    fun setVisualizationColor(color: Int) {
        visualization.setColor(color)
        invalidate()
    }

    fun addAudioBuffer(base64EncodedBuffer: String) {
        audioPlayer?.addBuffer(base64EncodedBuffer)
    }

    fun stopPlayback() {
        audioPlayer?.stopPlayback()
    }

    fun pausePlayback() {
        audioPlayer?.pausePlayback()
    }

    fun resumePlayback() {
        audioPlayer?.resumePlayback()
    }

    override fun playbackStarted() {
        isPlaying = true
        onPlaybackStarted(mapOf())
        invalidate()
    }

    override fun playbackStopped() {
        isPlaying = false
        onPlaybackStopped(mapOf())
        visualization.updateData(FloatArray(0))
        postInvalidate()
    }

    override fun bufferReady(buffer: ByteArray) {
        val floatArray = convertByteArrayToFloatArray(buffer)
        visualization.updateData(floatArray)
        postInvalidate()
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (isPlaying) {
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
        audioPlayer?.release()
    }
}
