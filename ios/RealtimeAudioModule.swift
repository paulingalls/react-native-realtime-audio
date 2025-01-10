import AVFoundation
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

public class RealtimeAudioModule:
    Module, RealtimeAudioPlayerDelegate {
    var hasListeners: Bool = false
    
    public func definition() -> ModuleDefinition {
        Name("RealtimeAudio")
        
        Events("onPlaybackStarted", "onPlaybackStopped")
        
        OnCreate {
            configureAudioSession()
        }

        OnStartObserving {
            hasListeners = true
        }

        OnStopObserving {
            hasListeners = false
        }
        
        AsyncFunction("checkAndRequestAudioPermissions") {
            let hasPermissions = await checkAndRequestAudioPermissions()
            return hasPermissions
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
    
    private func checkAndRequestAudioPermissions() async -> Bool  {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            guard granted else {
                print("Permission denied")
                return false
            }
            return true
        default:
            print("Permission denied")
        }
        return false
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { }
    }
}
