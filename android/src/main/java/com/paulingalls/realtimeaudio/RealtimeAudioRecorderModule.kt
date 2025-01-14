package com.paulingalls.realtimeaudio

import AudioFormatSettings
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import getAndroidColor
import mapAudioEncodingToFormat
import mapChannelCountToInputFormat

class RealtimeAudioRecorderModule : Module() {
    var hasListeners = false

    override fun definition() = ModuleDefinition {
        Name("RealtimeAudioRecorder")
        Events("onAudioCaptured", "onCaptureComplete")

        OnStartObserving {
            hasListeners = true
        }

        OnStopObserving {
            hasListeners = false
        }

        Class("RealtimeAudioRecorder", RealtimeAudioRecorder::class) {
            Constructor { format: AudioFormatSettings ->
                return@Constructor RealtimeAudioRecorder(
                    format.sampleRate,
                    mapChannelCountToInputFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                ).apply {
                    delegate = RealtimeEventDelegate(this@RealtimeAudioRecorderModule)
                }
            }

            AsyncFunction("startRecording") { recorder: RealtimeAudioRecorder ->
                recorder.startRecording()
            }
            AsyncFunction("stopRecording") { recorder: RealtimeAudioRecorder ->
                recorder.stopRecording()
            }
        }

        View(RealtimeAudioRecorderView::class) {
            Events("onAudioCaptured", "onCaptureComplete")

            Prop("waveformColor") { view: RealtimeAudioRecorderView, hexColor: String ->
                view.setVisualizationColor(getAndroidColor(hexColor))
            }

            Prop("audioFormat") { view: RealtimeAudioRecorderView,
                                  format: AudioFormatSettings ->
                view.setAudioFormat(
                    format.sampleRate,
                    mapChannelCountToInputFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                )
            }

            AsyncFunction("startRecording") { view: RealtimeAudioRecorderView ->
                view.startRecording()
            }

            AsyncFunction("stopRecording") { view: RealtimeAudioRecorderView ->
                view.stopRecording()
            }
        }
    }

    class RealtimeEventDelegate(
        private val module: RealtimeAudioRecorderModule
    ) : RealtimeAudioBufferDelegate {
        override fun audioStringReady(base64Audio: String) {
            if (module.hasListeners) {
                module.sendEvent(
                    "onAudioCaptured", mapOf(
                        "audioBuffer" to base64Audio
                    )
                )
            }
        }

        override fun bufferReady(buffer: ByteArray) {
        }

        override fun captureComplete() {
            if (module.hasListeners) {
                module.sendEvent("onCaptureComplete", mapOf())
            }
        }
    }
}