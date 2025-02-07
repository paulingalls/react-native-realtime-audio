import AVFoundation
import ExpoModulesCore

public class RealtimeAudioRecorderModule: Module, RealtimeAudioRecorderDelegate {
  var hasListeners: Bool = false
  
  public func definition() -> ModuleDefinition {
    Name("RealtimeAudioRecorder")
    
    Events("onAudioCaptured", "onCaptureComplete")
    
    OnStartObserving {
      hasListeners = true
    }
    
    OnStopObserving {
      hasListeners = false
    }
    
    Class(RealtimeAudioRecorder.self) {
      Constructor { (audioFormat: AudioFormatSettings, echoCancellationEnabled: Bool) -> RealtimeAudioRecorder in
        let recorder: RealtimeAudioRecorder = RealtimeAudioRecorder(sampleRate: audioFormat.sampleRate,
                                                                    channelCount: audioFormat.channelCount,
                                                                    audioFormat: getCommonFormat(audioFormat.encoding))!
        recorder.echoCancellationEnabled = echoCancellationEnabled
        recorder.delegate = self
        return recorder
      }
      
      AsyncFunction("startRecording") { (recorder: RealtimeAudioRecorder) in
        do {
          try recorder.startRecording()
        } catch {
          print("Error starting recording: \(error.localizedDescription)")
        }
      }
      
      AsyncFunction("stopRecording") { (recorder: RealtimeAudioRecorder) in
        recorder.stopRecording()
      }
    }
    
    View(RealtimeAudioRecorderView.self) {
      Events("onAudioCaptured", "onCaptureComplete")
      
      Prop("waveformColor") { (
        view: RealtimeAudioRecorderView,
        hexColor: UIColor
      ) in
        view.setWaveformColor(hexColor)
      }
      
      Prop("audioFormat") { (
        view: RealtimeAudioRecorderView,
        format: AudioFormatSettings
      ) in
        view.setAudioFormat(
          sampleRate: format.sampleRate,
          commonFormat: self.getCommonFormat(format.encoding),
          channels: format.channelCount
        )
      }
      
      Prop("visualizer") { (
        view: RealtimeAudioRecorderView,
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
        view: RealtimeAudioRecorderView,
        enabled: Bool
      ) in
        view.setEchoCancellationEnabled(enabled)
      }
      
      AsyncFunction("startRecording") { (view: RealtimeAudioRecorderView) in
        view.startRecording()
      }
      
      AsyncFunction("stopRecording") { (view: RealtimeAudioRecorderView) in
        view.stopRecording()
      }
    }
  }
  
  func base64BufferReady(_ base64Audio: String) {
    if (hasListeners) {
      let event = ["audioBuffer": base64Audio]
      sendEvent("onAudioCaptured", event)
    }
  }
  
  func bufferCaptured(_ buffer: AVAudioPCMBuffer) {
  }
  
  func audioRecorderDidFinishRecording() {
    if (hasListeners) {
      sendEvent("onCaptureComplete")
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
