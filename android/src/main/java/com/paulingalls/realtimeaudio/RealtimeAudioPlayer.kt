import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.util.Base64
import expo.modules.kotlin.sharedobjects.SharedObject
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.concurrent.thread

interface RealtimeAudioPlayerDelegate {
    fun playbackStarted()
    fun playbackStopped()
    fun bufferReady(buffer: ByteArray)
}

class RealtimeAudioPlayer(
    sampleRate: Int,
    channelConfig: Int,
    audioFormat: Int
) : SharedObject() {
    private var audioTrack: AudioTrack? = null
    private val bufferQueue = ConcurrentLinkedQueue<ByteArray>()
    @Volatile private var isPlaying = false
    @Volatile private var isPaused = false
    private var playerThread: Thread? = null

    var delegate: RealtimeAudioPlayerDelegate? = null

    init {
        val bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)
        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                // USAGE_VOICE_COMMUNICATION (paired with the VOICE_COMMUNICATION recorder
                // source and AudioManager.MODE_IN_COMMUNICATION) is what lets Android's
                // hardware AEC link the playback and capture streams. USAGE_MEDIA breaks
                // echo cancellation on speakerphone for AI voice loops.
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setEncoding(audioFormat)
                    .setChannelMask(channelConfig)
                    .build()
            )
            .setBufferSizeInBytes(bufferSize)
            .setTransferMode(AudioTrack.MODE_STREAM)
            .build()
    }

    fun addBuffer(base64EncodedBuffer: String) {
        val decodedBuffer = Base64.decode(base64EncodedBuffer, Base64.DEFAULT)
        bufferQueue.offer(decodedBuffer)
        if (!isPlaying && !isPaused && bufferQueue.isNotEmpty()) {
            startPlayback()
        }
    }

    private fun startPlayback() {
        if (isPlaying) return
        isPlaying = true
        isPaused = false
        audioTrack?.play()

        delegate?.playbackStarted()

        playerThread = thread(start = true) {
            var hasWaitedABitToSeeIfMoreBuffersComeSoon = false
            try {
                while (isPlaying) {
                    if (!isPaused) {
                        val buffer = bufferQueue.poll()
                        if (buffer != null) {
                            delegate?.bufferReady(buffer)
                            audioTrack?.write(buffer, 0, buffer.size)
                        } else {
                            if (!hasWaitedABitToSeeIfMoreBuffersComeSoon) {
                                Thread.sleep(300)
                                hasWaitedABitToSeeIfMoreBuffersComeSoon = true
                            } else {
                                isPlaying = false
                            }
                        }
                    } else {
                        Thread.sleep(100)
                    }
                }
            } catch (_: InterruptedException) {
                // stopPlayback() interrupted us; fall through to playbackStopped().
            }
            delegate?.playbackStopped()
        }
    }

    fun stopPlayback() {
        if (!isPlaying) return
        isPlaying = false
        isPaused = false
        bufferQueue.clear()
        // Stop the AudioTrack first so any in-flight blocking write() returns,
        // then interrupt to break out of the drain-wait Thread.sleep, then
        // bounded join so a misbehaving thread can't hang the caller.
        audioTrack?.stop()
        audioTrack?.flush()
        playerThread?.interrupt()
        playerThread?.join(1000L)
        playerThread = null
    }

    fun pausePlayback() {
        if (isPlaying && !isPaused) {
            isPaused = true
            audioTrack?.pause()
        }
    }

    fun resumePlayback() {
        if (isPlaying && isPaused) {
            isPaused = false
            audioTrack?.play()
        }
    }

    fun release() {
        delegate = null
        stopPlayback()
        audioTrack?.release()
        audioTrack = null
    }
}
