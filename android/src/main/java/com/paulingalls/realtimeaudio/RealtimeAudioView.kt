package com.paulingalls.realtimeaudio

import RealtimeAudioPlayer
import RealtimeAudioPlayerDelegate
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.max

class RealtimeAudioView(context: Context, appContext: AppContext) : ExpoView(context, appContext),
    RealtimeAudioPlayerDelegate {
    private val onPlaybackStarted by EventDispatcher()
    private val onPlaybackStopped by EventDispatcher()
    private var audioPlayer: RealtimeAudioPlayer? = null
    private val waveformPaint: Paint = Paint()
    private val waveformPath: Path = Path()
    private var waveformData: FloatArray = FloatArray(0)
    private var isPlaying = false

    init {
        waveformPaint.apply {
            color = Color.BLUE
            style = Paint.Style.STROKE
            strokeWidth = 2f
            isAntiAlias = true
        }
        setWillNotDraw(false)
    }

    fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioPlayer?.release()
        audioPlayer = RealtimeAudioPlayer(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioView
        }
    }

    fun setWaveformColor(color: Int) {
        waveformPaint.color = color
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
        waveformData = FloatArray(0)
        postInvalidate()
    }

    override fun bufferReady(buffer: ByteArray) {
        // Convert byte array to float array for waveform
        waveformData = convertByteArrayToFloatArray(buffer)
        post { invalidate() }
        postInvalidate()
    }

    private fun convertByteArrayToFloatArray(byteArray: ByteArray): FloatArray {
        val shortArray = ByteBuffer.wrap(byteArray).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val floatArray = FloatArray(shortArray.remaining())
        for (i in floatArray.indices) {
            floatArray[i] = shortArray.get(i).toFloat() / Short.MAX_VALUE
        }
        return floatArray
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)

        if (!isPlaying || waveformData.isEmpty()) return

        val width = width.toFloat()
        val height = height.toFloat()
        val centerY = height / 2

        waveformPath.reset()
        val step = max(1, waveformData.size / width.toInt())
        var x = 0f

        waveformPath.moveTo(0f, centerY)

        for (i in waveformData.indices step step) {
            val sampleValue = waveformData[i]
            val y = centerY + (sampleValue * height / 2)
            waveformPath.lineTo(x, y)
            x += width / (waveformData.size / step)
        }

        canvas.drawPath(waveformPath, waveformPaint)
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
