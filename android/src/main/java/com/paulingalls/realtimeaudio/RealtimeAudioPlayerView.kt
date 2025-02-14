package com.paulingalls.realtimeaudio

import RealtimeAudioPlayer
import RealtimeAudioPlayerDelegate
import android.content.Context
import android.media.AudioFormat
import convertByteArrayOfShortsToFloatArray
import convertByteArrayToFloatArray
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher

class RealtimeAudioPlayerView(
    context: Context, appContext: AppContext
) : BaseAudioView(context, appContext),
    RealtimeAudioPlayerDelegate {
    private val onPlaybackStarted by EventDispatcher()
    private val onPlaybackStopped by EventDispatcher()
    private var audioPlayer: RealtimeAudioPlayer? = null

    override fun setAudioFormat(sampleRate: Int, channelConfig: Int, audioFormat: Int) {
        audioPlayer?.release()
        audioPlayer = RealtimeAudioPlayer(sampleRate, channelConfig, audioFormat).apply {
            delegate = this@RealtimeAudioPlayerView
        }
        super.setAudioFormat(sampleRate, channelConfig, audioFormat)
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
        running = true
        onPlaybackStarted(mapOf())
        invalidate()
    }

    override fun playbackStopped() {
        running = false
        onPlaybackStopped(mapOf())
        handler.postDelayed({
            visualization.updateData(FloatArray(0))
            audioChunks.clear()
            chunkRenderTimeInMillis = 0
            postInvalidate()
        }, 300)
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
}
