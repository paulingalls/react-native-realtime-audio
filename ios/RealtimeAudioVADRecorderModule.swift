import AVFoundation
import ExpoModulesCore

public class RealtimeAudioVADRecorderModule: Module, RealtimeAudioVADRecorderDelegate {
  var hasListeners: Bool = false
  
  public func definition() -> ModuleDefinition {
    Name("RealtimeAudioVADRecorder")
    
    Events("onVoiceStarted", "onVoiceEnded", "onVoiceCaptured")
    
    OnStartObserving {
      hasListeners = true
    }
    
    OnStopObserving {
      hasListeners = false
    }
    
    Class(RealtimeAudioVADRecorder.self) {
      Constructor { (audioFormat: AudioFormatSettings, echoCancellationEnabled: Bool) -> RealtimeAudioVADRecorder in
        let recorder: RealtimeAudioVADRecorder = RealtimeAudioVADRecorder(sampleRate: audioFormat.sampleRate,
                                                                    channelCount: audioFormat.channelCount,
                                                                    audioFormat: getCommonFormat(audioFormat.encoding))!
        recorder.echoCancellationEnabled = echoCancellationEnabled
        recorder.delegate = self
        return recorder
      }
      
      AsyncFunction("startListening") { (recorder: RealtimeAudioVADRecorder) in
        recorder.startListening()
      }
      
      AsyncFunction("stopListening") { (recorder: RealtimeAudioVADRecorder) in
        recorder.stopListening()
      }
    }
    
    View(RealtimeAudioVADRecorderView.self) {
      Events("onVoiceStarted", "onVoiceEnded", "onVoiceCaptured")

      Prop("waveformColor") { (
        view: RealtimeAudioVADRecorderView,
        hexColor: UIColor
      ) in
        view.setWaveformColor(hexColor)
      }
      
      Prop("audioFormat") { (
        view: RealtimeAudioVADRecorderView,
        format: AudioFormatSettings
      ) in
        view.setAudioFormat(
          sampleRate: format.sampleRate,
          commonFormat: self.getCommonFormat(format.encoding),
          channels: format.channelCount
        )
      }

      Prop("visualizer") { (
        view: RealtimeAudioVADRecorderView,
        visualizer: String
      ) in
        if visualizer == "linearWaveform" {
          view.setVisualization(LinearWaveformVisualizer())
        } else if visualizer == "circularWaveform" {
          view.setVisualization(CircularWaveformVisualizer())
        } else if visualizer == "tripleCircle" {
          view.setVisualization(TripleCircleVisualizer())
        }
      }

      Prop("echoCancellationEnabled") { (
        view: RealtimeAudioVADRecorderView,
        enabled: Bool
      ) in
        view.setEchoCancellationEnabled(enabled)
      }
      
      AsyncFunction("startListening") { (view: RealtimeAudioVADRecorderView) in
        view.startListening()
      }
      
      AsyncFunction("stopListening") { (view: RealtimeAudioVADRecorderView) in
        view.stopListening()
      }
    }
  }
  
  func base64VoiceBufferReady(_ base64Audio: String) {
    if (hasListeners) {
      let event = ["audioBuffer": base64Audio]
      sendEvent("onVoiceCaptured", event)
    }
  }
  
  func voiceBufferCaptured(_ buffer: AVAudioPCMBuffer) {
  }
  
  func voiceDidStop() {
    if (hasListeners) {
      sendEvent("onVoiceEnded")
    }
  }

  func voiceDidStart() {
    if (hasListeners) {
      sendEvent("onVoiceStarted")
    }
  }
  

  private func getCommonFormat(_ encoding: AudioEncoding) -> AVAudioCommonFormat {
    switch encoding {
    case .pcm16bitInteger:
      return .pcmFormatInt16
    case .pcm32bitInteger:
      return .pcmFormatInt32
    case .pcm32bitFloat:
      return .pcmFormatFloat32
    case .pcm64bitFloat:
      return .pcmFormatFloat64
    }
  }
  
}
