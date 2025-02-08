import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioVADRecorderView: BaseAudioView {
  private var audioRecorder: RealtimeAudioVADRecorder?
  
  let onVoiceCaptured = EventDispatcher()
  let onVoiceStarted = EventDispatcher()
  let onVoiceEnded = EventDispatcher()

  public required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setAudioFormat(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32) {
    audioRecorder = RealtimeAudioVADRecorder(sampleRate: sampleRate, channelCount: channels, audioFormat: commonFormat)
    audioRecorder?.delegate = self
    audioRecorder?.echoCancellationEnabled = echoCancellationEnabled
  }
  
  func startListening() {
    audioRecorder?.startListening()
  }
  
  func stopListening() {
    audioRecorder?.stopListening()
  }
  
  func setEchoCancellationEnabled(_ enabled: Bool) {
    echoCancellationEnabled = enabled
    audioRecorder?.echoCancellationEnabled = enabled
  }
}

extension RealtimeAudioVADRecorderView: RealtimeAudioVADRecorderDelegate {
  func base64VoiceBufferReady(_ base64Audio: String) {
    let event = ["audioBuffer": base64Audio]
    onVoiceCaptured(event)
  }
  
  func voiceBufferCaptured(_ buffer: AVAudioPCMBuffer) {
    updateVisualizationSamples(from: buffer)
  }
  
  func voiceDidStart() {
    onVoiceStarted()
  }
  
  func voiceDidStop() {
    visualization.clearVisualization()
    onVoiceEnded()
  }
}
