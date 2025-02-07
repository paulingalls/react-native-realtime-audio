import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioPlayerView: ExpoView {
  private var audioPlayer: RealtimeAudioPlayer?
  private var visualization: AudioVisualization
  
  let onPlaybackStarted = EventDispatcher()
  let onPlaybackStopped = EventDispatcher()
  
  public required init(appContext: AppContext? = nil) {
    self.visualization = LinearWaveformVisualizer()
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
  
  func setVisualization(_ visualization: AudioVisualization) {
    layer.replaceSublayer(self.visualization.layer, with: visualization.layer)
    self.visualization = visualization
  }
  
  func setAudioFormat(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32) {
    audioPlayer = RealtimeAudioPlayer(
      sampleRate: sampleRate,
      commonFormat: commonFormat,
      channels: channels
    )
    audioPlayer?.delegate = self
  }
  
  func addBuffer(_ base64String: String) {
    audioPlayer?.addBuffer(base64String)
  }
  
  func resume() {
    audioPlayer?.resume()
  }
  
  func pause() {
    audioPlayer?.pause()
  }
  
  func stop() {
    audioPlayer?.stop()
  }
  
  func setWaveformColor(_ hexColor: UIColor) {
    visualization.setColor(hexColor)
  }
  
  private func updateVisualizationSamples(from buffer: AVAudioPCMBuffer) {
    let samplePieces = visualization.getSamplesFromAudio(buffer)
    if samplePieces.isEmpty { return }
    
    let sampleRate = Float(buffer.format.sampleRate)
    let sampleCount = samplePieces[0].count
    
    // Calculate the duration of each piece
    let pieceDuration = Float(sampleCount) / sampleRate
    
    // Use DispatchQueue to schedule the updates
    let queue = DispatchQueue(label: "os.react-native-real-time-audio.player-visualization", qos: .userInteractive)
    
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

extension RealtimeAudioPlayerView: RealtimeAudioPlayerDelegate {
  func audioPlayerDidStartPlaying() {
    onPlaybackStarted()
  }
  
  func audioPlayerDidStopPlaying() {
    visualization.clearVisualization()
    onPlaybackStopped()
  }
  
  func audioPlayerBufferDidBecomeAvailable(_ buffer: AVAudioPCMBuffer) {
    updateVisualizationSamples(from: buffer)
  }
}
