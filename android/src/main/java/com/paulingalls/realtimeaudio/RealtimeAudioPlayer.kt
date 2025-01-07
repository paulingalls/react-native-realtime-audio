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
    private val sampleRate: Int,
    private val channelConfig: Int,
    private val audioFormat: Int
) : SharedObject() {
    private var audioTrack: AudioTrack? = null
    private val bufferQueue = ConcurrentLinkedQueue<ByteArray>()
    private var isPlaying = false
    private var isPaused = false
    private var playerThread: Thread? = null

    var delegate: RealtimeAudioPlayerDelegate? = null

    init {
        initAudioTrack()
    }

    private fun initAudioTrack() {
        val bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)
        audioTrack = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
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
        if (!isPlaying && !isPaused) {
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
            while (isPlaying) {
                if (!isPaused) {
                    val buffer = bufferQueue.poll()
                    if (buffer != null) {
                        delegate?.bufferReady(buffer)
                        audioTrack?.write(buffer, 0, buffer.size)
                    } else {
                        isPlaying = false
                    }
                } else {
                    Thread.sleep(100)
                }
            }
            delegate?.playbackStopped()
        }
    }

    fun stopPlayback() {
        if (!isPlaying) return
        isPlaying = false
        isPaused = false
        playerThread?.join()
        audioTrack?.stop()
        audioTrack?.flush()
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
        stopPlayback()
        audioTrack?.release()
        audioTrack = null
    }
}
