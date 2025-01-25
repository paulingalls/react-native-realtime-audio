import AVFoundation
import ExpoModulesCore

public class RealtimeAudioPlayerModule:
  Module, RealtimeAudioPlayerDelegate {
  var hasListeners: Bool = false
  
  public func definition() -> ModuleDefinition {
    Name("RealtimeAudioPlayer")
    
    Events("onPlaybackStarted", "onPlaybackStopped")
    
    OnStartObserving {
      hasListeners = true
    }
    
    OnStopObserving {
      hasListeners = false
    }
    
    Class(RealtimeAudioPlayer.self) {
      Constructor { (audioFormat: AudioFormatSettings) -> RealtimeAudioPlayer in
        let player: RealtimeAudioPlayer = RealtimeAudioPlayer(sampleRate: audioFormat.sampleRate,
                                                              commonFormat: getCommonFormat(audioFormat.encoding),
                                                              channels: audioFormat.channelCount)!
        player.delegate = self
        return player
      }
      
      // Functions
      AsyncFunction("addBuffer") { (
        player: RealtimeAudioPlayer,
        base64String: String
      ) in
        player.addBuffer(base64String)
      }
      
      AsyncFunction("resume") { (player: RealtimeAudioPlayer) in
        player.resume()
      }
      
      AsyncFunction("pause") { (player: RealtimeAudioPlayer) in
        player.pause()
      }
      
      AsyncFunction("stop") { (player: RealtimeAudioPlayer) in
        player.stop()
      }
    }
    
    View(RealtimeAudioPlayerView.self) {
      Events("onPlaybackStarted", "onPlaybackStopped")
      
      // Props
      Prop("waveformColor") { (
        view: RealtimeAudioPlayerView,
        hexColor: UIColor
      ) in
        view.setWaveformColor(hexColor)
      }
      
      Prop("audioFormat") { (
        view: RealtimeAudioPlayerView,
        format: AudioFormatSettings
      ) in
        view.setAudioFormat(
          sampleRate: format.sampleRate,
          commonFormat: self.getCommonFormat(format.encoding),
          channels: format.channelCount
        )
      }
      
      // Functions
      AsyncFunction("addBuffer") { (
        view: RealtimeAudioPlayerView,
        base64String: String
      ) in
        view.addBuffer(base64String)
      }
      
      AsyncFunction("resume") { (view: RealtimeAudioPlayerView) in
        view.resume()
      }
      
      AsyncFunction("pause") { (view: RealtimeAudioPlayerView) in
        view.pause()
      }
      
      AsyncFunction("stop") { (view: RealtimeAudioPlayerView) in
        view.stop()
      }
    }
  }
  
  func audioPlayerDidStartPlaying() {
    if hasListeners { sendEvent("onPlaybackStarted") }
  }
  
  func audioPlayerDidStopPlaying() {
    if hasListeners { sendEvent("onPlaybackStopped") }
  }
  
  func audioPlayerBufferDidBecomeAvailable(_ buffer: AVAudioPCMBuffer) {
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
