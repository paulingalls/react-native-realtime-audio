import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioPlayerView: BaseAudioView {
  private var audioPlayer: RealtimeAudioPlayer?
  
  let onPlaybackStarted = EventDispatcher()
  let onPlaybackStopped = EventDispatcher()
  
  public required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      audioPlayer?.stop()
    }
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
    guard isAttachedToWindow else { return }
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
