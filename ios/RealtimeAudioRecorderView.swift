//
//  RealtimeAudioRecorderView.swift
//  Pods
//
//  Created by Paul Ingalls on 1/9/25.
//

import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioRecorderView: ExpoView {
  private var audioRecorder: RealtimeAudioRecorder?
  private var visualization: AudioVisualization
  private var echoCancellationEnabled: Bool = false
  
  let onAudioCaptured = EventDispatcher()
  let onCaptureComplete = EventDispatcher()
  
  public required init(appContext: AppContext? = nil) {
    self.visualization = WaveformVisualization()
    super.init(appContext: appContext)
    
    layer.addSublayer(visualization.layer)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    visualization.setFrame(bounds)
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
  
  func setWaveformColor(_ hexColor: UIColor) {
    visualization.setColor(hexColor)
  }
  
  func setEchoCancellationEnabled(_ enabled: Bool) {
    echoCancellationEnabled = enabled
    audioRecorder?.echoCancellationEnabled = enabled
  }
  
  private func updateVisualizationSamples(from buffer: AVAudioPCMBuffer) {
    let samplePieces = visualization.getSamplesFromAudio(buffer)
    let sampleRate = Float(buffer.format.sampleRate)
    let sampleCount = samplePieces[0].count
    
    // Calculate the duration of each piece
    let pieceDuration = Float(sampleCount) / sampleRate
    
    // Use DispatchQueue to schedule the updates
    let queue = DispatchQueue(label: "os.react-native-real-time-audio.recording-visualization", qos: .userInteractive)
    
    for (index, samples) in samplePieces.enumerated() {
      let delay = Double(Float(index) * pieceDuration)
      
      queue.asyncAfter(deadline: .now() + delay) { [weak self] in
        DispatchQueue.main.async {
          self?.visualization.updateVisualization(with: samples)
        }
      }
    }
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
