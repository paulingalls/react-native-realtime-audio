package com.paulingalls.realtimeaudio

import RealtimeAudioPlayer
import RealtimeAudioPlayerDelegate
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

class RealtimeAudioPlayerView(
    context: Context, appContext: AppContext
) : ExpoView(context, appContext),
    RealtimeAudioPlayerDelegate {
    private val onPlaybackStarted by EventDispatcher()
    private val onPlaybackStopped by EventDispatcher()
    private var audioPlayer: RealtimeAudioPlayer? = null
    private var visualization: AudioVisualization = LinearWaveformVisualizer()
    private var audioChunks: ArrayList<FloatArray> = ArrayList()
    private val handler = Handler(Looper.getMainLooper())
    private var isPlaying = false
    private var channelCount: Int = 1
    private var sampleRate: Int = 0
    private var audioFormat: Int = 0
    private var mainColor: Int = Color.BLUE

    init {
        setWillNotDraw(false)
        visualization.setColor(mainColor)
    }

    fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioPlayer?.release()
        audioPlayer = RealtimeAudioPlayer(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioPlayerView
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
        audioChunks.clear()
        postInvalidate()
    }

    override fun bufferReady(buffer: ByteArray) {
        val floatArray: FloatArray
        if (audioFormat == AudioFormat.ENCODING_PCM_16BIT) {
            floatArray = convertByteArrayOfShortsToFloatArray(buffer)
        } else {
            floatArray = convertByteArrayToFloatArray(buffer)
        }
        val chunkSize = width
        val newChunks = visualization.getSampleChunksFromAudio(floatArray, channelCount, chunkSize)
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

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        if (isPlaying && audioChunks.size > 0) {
            val chunk = audioChunks.removeAt(0)
            visualization.updateData(chunk)
            visualization.draw(canvas, width.toFloat(), height.toFloat())
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        audioPlayer?.release()
    }
}
