package com.paulingalls.realtimeaudio

import AudioFormatSettings
import RealtimeAudioPlayer
import RealtimeAudioPlayerDelegate
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import getAndroidColor
import mapAudioEncodingToFormat
import mapChannelCountToOutputFormat

class RealtimeAudioPlayerModule : Module() {
    var hasListeners = false

    override fun definition() = ModuleDefinition {
        Name("RealtimeAudioPlayer")
        Events("onPlaybackStarted", "onPlaybackStopped")

        OnStartObserving {
            hasListeners = true
        }

        OnStopObserving {
            hasListeners = false
        }

        Class("RealtimeAudioPlayer", RealtimeAudioPlayer::class) {
            Constructor { format: AudioFormatSettings ->
                return@Constructor RealtimeAudioPlayer(
                    format.sampleRate,
                    mapChannelCountToOutputFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                ).apply {
                    delegate = RealtimeEventDelegate(this@RealtimeAudioPlayerModule)
                }
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

        View(RealtimeAudioPlayerView::class) {
            Events("onPlaybackStarted", "onPlaybackStopped")

            Prop("waveformColor") { view: RealtimeAudioPlayerView, hexColor: String ->
                view.setVisualizationColor(getAndroidColor(hexColor))
            }

            Prop("audioFormat") { view: RealtimeAudioPlayerView, format: AudioFormatSettings ->
                view.setAudioFormat(
                    format.sampleRate,
                    mapChannelCountToOutputFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                )
            }

            AsyncFunction("addBuffer") { view: RealtimeAudioPlayerView, base64String: String ->
                view.addAudioBuffer(base64String)
            }
            AsyncFunction("pause") { view: RealtimeAudioPlayerView ->
                view.pausePlayback()
            }
            AsyncFunction("resume") { view: RealtimeAudioPlayerView ->
                view.resumePlayback()
            }
            AsyncFunction("stop") { view: RealtimeAudioPlayerView ->
                view.stopPlayback()
            }
        }
    }

    class RealtimeEventDelegate(
        private val module: RealtimeAudioPlayerModule
    ) : RealtimeAudioPlayerDelegate {

        override fun playbackStarted() {
            if (module.hasListeners) {
                module.sendEvent("onPlaybackStarted")
            }
        }

        override fun playbackStopped() {
            if (module.hasListeners) {
                module.sendEvent("onPlaybackStopped")
            }
        }

        override fun bufferReady(buffer: ByteArray) {
        }
    }

}
