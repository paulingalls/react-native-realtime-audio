import ExpoModulesCore

enum AudioEncoding: String, Enumerable {
    case pcm16bitInteger
    case pcm32bitInteger
    case pcm32bitFloat
    case pcm64bitFloat
}

struct AudioFormatSettings: Record {
    @Field public var sampleRate: Double = 24000
    @Field public var encoding: AudioEncoding = .pcm16bitInteger
    @Field public var channelCount: UInt32 = 1
    @Field public var interleaved: Bool = false
}

public class RealtimeAudioModule: Module, RealtimeAudioPlayerDelegate {
    var hasListeners: Bool = false
    
    public func definition() -> ModuleDefinition {
        Name("RealtimeAudio")
        
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
                                                                             channels: audioFormat.channelCount,
                                                                             interleaved: audioFormat.interleaved)!
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
        
        // Enables the module to be used as a native view. Definition components that are accepted as part of the
        // view definition: Prop, Events.
        View(RealtimeAudioView.self) {
            Events("onPlaybackStarted", "onPlaybackStopped")

            // Props
            Prop("waveformColor") { (
                view: RealtimeAudioView,
                hexColor: UIColor
            ) in
                view.setWaveformColor(hexColor)
            }
            
            Prop("audioFormat") { (
                view: RealtimeAudioView,
                format: AudioFormatSettings
            ) in
                view.setAudioFormat(
                        sampleRate: format.sampleRate,
                        commonFormat: self.getCommonFormat(format.encoding),
                        channels: format.channelCount,
                        interleaved: format.interleaved
                    )
            }
            
            // Functions
            AsyncFunction("addBuffer") { (
                view: RealtimeAudioView,
                base64String: String
            ) in
                view.addBuffer(base64String)
            }
            
            AsyncFunction("resume") { (view: RealtimeAudioView) in
                view.resume()
            }
            
            AsyncFunction("pause") { (view: RealtimeAudioView) in
                view.pause()
            }
            
            AsyncFunction("stop") { (view: RealtimeAudioView) in
                view.stop()
            }
        }
    }
    
    func audioPlayerDidStartPlaying() {
        sendEvent("onPlaybackStarted")
    }
    
    func audioPlayerDidStopPlaying() {
        sendEvent("onPlaybackStopped")
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
