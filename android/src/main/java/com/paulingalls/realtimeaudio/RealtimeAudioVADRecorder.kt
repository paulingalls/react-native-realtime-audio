package com.paulingalls.realtimeaudio

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.util.Base64
import com.tagtraum.pcmsampledsp.Rational
import com.tagtraum.pcmsampledsp.Resampler
import convertByteArrayToFloatArray
import convertFloatArrayToByteArray
import convertShortArrayToByteArray
import expo.modules.kotlin.sharedobjects.SharedObject
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.nio.ByteBuffer

interface RealtimeAudioVoiceDelegate {
    fun audioStringReady(base64Audio: String)
    fun voiceBufferReady(buffer: FloatArray)
    fun voiceStarted()
    fun voiceStopped()
}

private const val VAD_SAMPLE_RATE = 16000
private const val VAD_CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
private const val VAD_AUDIO_FORMAT = AudioFormat.ENCODING_PCM_FLOAT

class RealtimeAudioVADRecorder(
    private val sampleRate: Int,
    private val channelConfig: Int,
    private val audioFormat: Int = AudioFormat.ENCODING_PCM_16BIT
) : SharedObject() {
    var delegate: RealtimeAudioVoiceDelegate? = null
    var isEchoCancellationEnabled = false
    var modelPath: String = ""

    private var audioRecord: AudioRecord? = null
    private var isListening = false
    private var isSpeaking = false
    private var recordingJob: Job? = null
    private val recordingScope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private var vadIterator: VadIterator? = null
    private val resampler = Resampler(Rational(sampleRate, VAD_SAMPLE_RATE))
    private var bufferSize = 0
    private val minBufferSize: Int =
        AudioRecord.getMinBufferSize(VAD_SAMPLE_RATE, VAD_CHANNEL_CONFIG, VAD_AUDIO_FORMAT)

    fun startListening() {
        if (isListening) return

        try {
            bufferSize = 512 * Float.SIZE_BYTES
            if (bufferSize < minBufferSize) {
                bufferSize *= 2
            }
            if (bufferSize < minBufferSize) {
                bufferSize *= 512 * Float.SIZE_BYTES * 3
            }
            if (bufferSize < minBufferSize) {
                throw Exception("Buffer size is too small")
            }
            initializeVAD()
            initializeAudioRecord()
            audioRecord?.startRecording()
            isListening = true
            startRecordingJob()
        } catch (e: Exception) {
            print("error starting to record $e")
        }
    }

    fun stopListening() {
        isListening = false
        recordingJob?.cancel()
        audioRecord?.apply {
            stop()
            release()
        }
        audioRecord = null
        delegate?.voiceStopped()
    }

    private fun initializeVAD() {
        if (modelPath.isEmpty()) {
            throw Exception("Model path is empty")
        }
        if (vadIterator != null) {
            vadIterator?.resetState()
            return
        }

        vadIterator = VadIterator(
            modelPath,
            VAD_SAMPLE_RATE.toLong(),
            32,
            0.5f,
            1500)
    }

    @SuppressLint("MissingPermission")
    private fun initializeAudioRecord() {
        var source = MediaRecorder.AudioSource.MIC
        if (isEchoCancellationEnabled) {
            source = MediaRecorder.AudioSource.VOICE_COMMUNICATION
        }
        audioRecord = AudioRecord(
            source,
            VAD_SAMPLE_RATE,
            VAD_CHANNEL_CONFIG,
            VAD_AUDIO_FORMAT,
            bufferSize
        )
    }

    private fun startRecordingJob() {
        recordingJob = recordingScope.launch {
            val buffer = ByteBuffer.allocateDirect(bufferSize)
            val vadBufferSize = 512 * Float.SIZE_BYTES
            while (isActive) {
                val bufferLength = audioRecord?.read(buffer, bufferSize) ?: -1

                if (bufferLength > 0 && bufferLength % vadBufferSize == 0) {
                    var position = 0
                    while( position < bufferLength - 1) {
                        val chunkSize = minOf(vadBufferSize, bufferLength - position)
                        val byteArray = ByteArray(chunkSize)
                        buffer.get(byteArray, 0, chunkSize)
                        position += chunkSize
                        val floatArray = convertByteArrayToFloatArray(byteArray)
                        val hasVoice = vadIterator?.predict(floatArray)
                        if (hasVoice == true) {
                            if (!isSpeaking) {
                                delegate?.voiceStarted()
                                isSpeaking = true
                            }
                            val resampledBufferSize = floatArray.size * sampleRate / VAD_SAMPLE_RATE
                            val resampled = getResampledBuffer(floatArray, resampledBufferSize)
                            delegate?.voiceBufferReady(resampled)
                            var bitsArray: ByteArray
                            if (audioFormat == AudioFormat.ENCODING_PCM_16BIT) {
                                val shortArray = ShortArray(resampled.size) { i ->
                                    (resampled[i] * Short.MAX_VALUE).toInt().toShort()
                                }
                                bitsArray = convertShortArrayToByteArray(shortArray)
                            } else {
                                bitsArray = convertFloatArrayToByteArray(resampled)
                            }
                            val base64Data =
                                Base64.encodeToString(bitsArray, 0, bitsArray.size, Base64.NO_WRAP)
                            delegate?.audioStringReady(base64Data)
                        } else {
                            if (isSpeaking) {
                                delegate?.voiceStopped()
                                isSpeaking = false
                            }
                        }
                    }
                    buffer.clear()
                } else {
                    print("Error reading audio data: $bufferLength")
                }
            }
        }
    }

    private fun getResampledBuffer(buffer: FloatArray, refactoredSamples: Int): FloatArray {
        val resampledBuffer = FloatArray(refactoredSamples)
        resampler.resample(buffer, resampledBuffer, 0, 1)
        return resampledBuffer
    }

    fun release() {
        stopListening()
        recordingScope.cancel()
    }
}