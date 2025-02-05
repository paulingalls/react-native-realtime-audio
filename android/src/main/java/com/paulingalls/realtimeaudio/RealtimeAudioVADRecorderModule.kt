package com.paulingalls.realtimeaudio

import AudioFormatSettings
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import mapAudioEncodingToFormat
import mapChannelCountToInputFormat

class RealtimeAudioVADRecorderModule : Module() {
    var hasListeners = false
    private var modelPath: String? = ""

    override fun definition() = ModuleDefinition {
        Name("RealtimeAudioVADRecorder")
        Events("onVoiceCaptured", "onVoiceStarted", "onVoiceEnded")

        OnCreate {
            modelPath = AssetUtil.getAssetFilePath(appContext.reactContext!!.applicationContext, "silero_vad_16k_op15.onnx")
        }

        OnStartObserving {
            hasListeners = true
        }

        OnStopObserving {
            hasListeners = false
        }

        Class("RealtimeAudioVADRecorder", RealtimeAudioVADRecorder::class) {
            Constructor { format: AudioFormatSettings, echoCancellationEnabled: Boolean ->
                return@Constructor RealtimeAudioVADRecorder(
                    format.sampleRate,
                    mapChannelCountToInputFormat(format.channelCount),
                    mapAudioEncodingToFormat(format.encoding)
                ).apply {
                    isEchoCancellationEnabled = echoCancellationEnabled
                    delegate = RealtimeVADEventDelegate(this@RealtimeAudioVADRecorderModule)
                    modelPath = this@RealtimeAudioVADRecorderModule.modelPath!!
                }
            }

            AsyncFunction("startListening") { recorder: RealtimeAudioVADRecorder ->
                recorder.startListening()
            }
            AsyncFunction("stopListening") { recorder: RealtimeAudioVADRecorder ->
                recorder.stopListening()
            }
        }
    }

    class RealtimeVADEventDelegate(
        private val module: RealtimeAudioVADRecorderModule
    ) : RealtimeAudioVoiceDelegate {
        override fun audioStringReady(base64Audio: String) {
            if (module.hasListeners) {
                module.sendEvent(
                    "onVoiceCaptured", mapOf(
                        "audioBuffer" to base64Audio
                    )
                )
            }
        }

        override fun voiceBufferReady(buffer: FloatArray) {}

        override fun voiceStarted() {
            if (module.hasListeners) {
                module.sendEvent("onVoiceStarted", mapOf())
            }
        }

        override fun voiceStopped() {
            if (module.hasListeners) {
                module.sendEvent("onVoiceEnded", mapOf())
            }
        }
    }
}