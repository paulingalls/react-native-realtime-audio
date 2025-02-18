package com.paulingalls.realtimeaudio

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.media.AudioFormat
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView
import kotlin.math.floor

open class BaseAudioView(
    context: Context, appContext: AppContext
) : ExpoView(context, appContext) {
    protected var running: Boolean = false
    protected var visible: Boolean = false
    protected var visualization: AudioVisualization = BarGraphVisualizer()
    protected var audioChunks: ArrayList<FloatArray> = ArrayList()
    protected var audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
    protected var chunkRenderTimeInMillis: Long = 0

    private val handler = Handler(Looper.getMainLooper())
    private var channelCount: Int = 1
    private var sampleRate: Int = 24000
    private var mainColor: Int = Color.BLUE

    init {
        setWillNotDraw(false)
        visualization.setColor(mainColor)
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        visible = true
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        visible = false
    }

    open fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        channelCount = if (channelConfig == AudioFormat.CHANNEL_OUT_STEREO) {
            2
        } else {
            1
        }
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

    fun scheduleChunks(samples: FloatArray) {
        if (!running || !visible) {
            return
        }

        if (chunkRenderTimeInMillis == 0L) {
            chunkRenderTimeInMillis = SystemClock.uptimeMillis()
        }

        val frameDurationInMillis = 25
        val chunkSize = floor((sampleRate.toFloat() * frameDurationInMillis.toFloat()) / 1000.0).toInt()
        val newChunks = visualization.getSampleChunksFromAudio(samples, channelCount, chunkSize)
        val chunkDuration =
            ((samples.size.toFloat() * 1000.0) / (sampleRate.toFloat() * newChunks.size.toFloat())).toLong()
        audioChunks.addAll(newChunks)
        for (chunkIndex in 0 until newChunks.size) {
            handler.postAtTime({
                postInvalidateOnAnimation()
            }, chunkRenderTimeInMillis)
            chunkRenderTimeInMillis += chunkDuration
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (visible && running && audioChunks.size > 0) {
            val chunk = audioChunks.removeAt(0)
            visualization.updateData(chunk)
            visualization.draw(canvas, width.toFloat(), height.toFloat())
        }
    }
}