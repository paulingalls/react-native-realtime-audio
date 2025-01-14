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
}

public class RealtimeAudioModule:
    Module {
    
    public func definition() -> ModuleDefinition {
        Name("RealtimeAudio")
        
        OnCreate {
            configureAudioSession()
        }
        
        AsyncFunction("checkAndRequestAudioPermissions") {
            let hasPermissions = await checkAndRequestAudioPermissions()
            return hasPermissions
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
