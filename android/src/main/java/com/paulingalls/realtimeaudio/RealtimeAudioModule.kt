package com.paulingalls.realtimeaudio

import RealtimeAudioPlayer
import android.graphics.Color
import android.media.AudioFormat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field
import expo.modules.kotlin.records.Record
import expo.modules.kotlin.types.Enumerable

enum class AudioEncoding(val value: String) : Enumerable {
    pcm16bitInteger("pcm16bitInteger"),
    pcm32bitInteger("pcm32bitInteger"),
    pcm32bitFloat("pcm32bitFloat"),
    pcm64bitFloat("pcm64bitFloat")
}


class AudioFormatSettings : Record {
    @Field
    val sampleRate: Int = 24000

    @Field
    val encoding: AudioEncoding = AudioEncoding.pcm16bitInteger

    @Field
    val channelCount: Int = 1

    @Field
    val interleaved: Boolean? = null
}

class RealtimeAudioModule : Module() {
    override fun definition() = ModuleDefinition {
        Name("RealtimeAudio")
        Events("onPlaybackStarted", "onPlaybackStopped")

        Class("RealtimeAudioPlayer", RealtimeAudioPlayer::class) {
            Constructor { format: AudioFormatSettings ->
                return@Constructor RealtimeAudioPlayer(
                    format.sampleRate,
                    mapChannelCountToFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                )
            }

            AsyncFunction("addBuffer") { player: RealtimeAudioPlayer, base64String: String ->
                player.addBuffer(base64String)
            }
            AsyncFunction("pause") { player: RealtimeAudioPlayer ->
                player.pausePlayback()
            }
            AsyncFunction("resume") { player: RealtimeAudioPlayer ->
                player.resumePlayback()
            }
            AsyncFunction("stop") { player: RealtimeAudioPlayer ->
                player.stopPlayback()
            }
        }

        View(RealtimeAudioView::class) {
            Events("onPlaybackStarted", "onPlaybackStopped")

            Prop("waveformColor") { view: RealtimeAudioView, hexColor: String ->
                view.setWaveformColor(getAndroidColor(hexColor))
            }

            Prop("audioFormat") { view: RealtimeAudioView, format: AudioFormatSettings ->
                view.setAudioFormat(
                    format.sampleRate,
                    mapChannelCountToFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                )
            }

            AsyncFunction("addBuffer") { view: RealtimeAudioView, base64String: String ->
                view.addAudioBuffer(base64String)
            }
            AsyncFunction("pause") { view: RealtimeAudioView ->
                view.pausePlayback()
            }
            AsyncFunction("resume") { view: RealtimeAudioView ->
                view.resumePlayback()
            }
            AsyncFunction("stop") { view: RealtimeAudioView ->
                view.stopPlayback()
            }
        }
    }

    private fun getAndroidColor(hexString: String ): Int {
        val cleanString = hexString.trim().lowercase()
        if (cleanString[0] == '#' && cleanString.length == 4) {
            val r = cleanString[1].toString().repeat(2).toInt(16)
            val g = cleanString[2].toString().repeat(2).toInt(16)
            val b = cleanString[3].toString().repeat(2).toInt(16)
            return Color.rgb(r, g, b)
        }
        return Color.parseColor(cleanString)
    }

    private fun mapAudioEncodingToFormat(encoding: AudioEncoding): Int {
        return when (encoding) {
            AudioEncoding.pcm16bitInteger -> AudioFormat.ENCODING_PCM_16BIT
            AudioEncoding.pcm32bitInteger -> AudioFormat.ENCODING_PCM_32BIT
            AudioEncoding.pcm32bitFloat -> AudioFormat.ENCODING_PCM_FLOAT
            AudioEncoding.pcm64bitFloat -> AudioFormat.ENCODING_PCM_FLOAT
        }
    }

    private fun mapChannelCountToFormat(channelCount: Int): Int {
        if (channelCount == 2) return AudioFormat.CHANNEL_OUT_STEREO
        return AudioFormat.CHANNEL_OUT_MONO
    }

}
