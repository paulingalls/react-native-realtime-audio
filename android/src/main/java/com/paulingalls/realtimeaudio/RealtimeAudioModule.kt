package com.paulingalls.realtimeaudio

import AudioFormatSettings
import RealtimeAudioPlayer
import RealtimeAudioPlayerDelegate
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import getAndroidColor
import mapAudioEncodingToFormat
import mapChannelCountToOutputFormat

class RealtimeAudioModule : Module() {
    var hasListeners = false

    override fun definition() = ModuleDefinition {
        Name("RealtimeAudio")
        Events("onPlaybackStarted", "onPlaybackStopped")

        OnStartObserving {
            hasListeners = true
        }

        OnStopObserving {
            hasListeners = false
        }

        AsyncFunction("checkAndRequestAudioPermissions") {
            val hasPermissions = checkAndRequestAudioPermissions()
            hasPermissions
        }

        Class("RealtimeAudioPlayer", RealtimeAudioPlayer::class) {
            Constructor { format: AudioFormatSettings ->
                return@Constructor RealtimeAudioPlayer(
                    format.sampleRate,
                    mapChannelCountToOutputFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                ).apply {
                    delegate = RealtimeEventDelegate(this@RealtimeAudioModule)
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

        View(RealtimeAudioView::class) {
            Events("onPlaybackStarted", "onPlaybackStopped")

            Prop("waveformColor") { view: RealtimeAudioView, hexColor: String ->
                view.setVisualizationColor(getAndroidColor(hexColor))
            }

            Prop("audioFormat") { view: RealtimeAudioView, format: AudioFormatSettings ->
                view.setAudioFormat(
                    format.sampleRate,
                    mapChannelCountToOutputFormat(format.channelCount),
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

    private fun checkAndRequestAudioPermissions(): Boolean {
        if (appContext.reactContext!!.checkSelfPermission(
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            val permissions = arrayOf(Manifest.permission.RECORD_AUDIO)
            ActivityCompat.requestPermissions(appContext.currentActivity!!, permissions, 0)
        } else {
            return true;
        }
        return appContext.reactContext!!.checkSelfPermission(
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    class RealtimeEventDelegate(
        private val module: RealtimeAudioModule
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
