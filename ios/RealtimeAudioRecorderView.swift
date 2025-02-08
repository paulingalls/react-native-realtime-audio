import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioRecorderView: BaseAudioView {
  private var audioRecorder: RealtimeAudioRecorder?
  
  let onAudioCaptured = EventDispatcher()
  let onCaptureComplete = EventDispatcher()
  
  public required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setAudioFormat(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32) {
    audioRecorder = RealtimeAudioRecorder(sampleRate: sampleRate, channelCount: channels, audioFormat: commonFormat)
    audioRecorder?.delegate = self
    audioRecorder?.echoCancellationEnabled = echoCancellationEnabled
  }
  
  func startRecording() {
    do {
      try audioRecorder?.startRecording()
    } catch {
      print("Error starting recording: \(error.localizedDescription)")
    }
  }
  
  func stopRecording() {
    audioRecorder?.stopRecording()
  }
  
  func setEchoCancellationEnabled(_ enabled: Bool) {
    echoCancellationEnabled = enabled
    audioRecorder?.echoCancellationEnabled = enabled
  }
}

extension RealtimeAudioRecorderView: RealtimeAudioRecorderDelegate {
  func base64BufferReady(_ base64Audio: String) {
    let event = ["audioBuffer": base64Audio]
    onAudioCaptured(event)
  }
  
  func bufferCaptured(_ buffer: AVAudioPCMBuffer) {
    updateVisualizationSamples(from: buffer)
  }
  
  func audioRecorderDidFinishRecording() {
    visualization.clearVisualization()
    onCaptureComplete()
  }
}
