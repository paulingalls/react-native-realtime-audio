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
    DispatchQueue.main.async {
      do {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .mixWithOthers])
        try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        if #available(iOS 18.2, *) {
          if AVAudioSession.sharedInstance().isEchoCancelledInputAvailable {
            try AVAudioSession.sharedInstance().setPrefersEchoCancelledInput(true) // Enable echo cancellation
          } else {
            print("Echo cancellation not supported on this device")
          }
        } else {
          print("Echo cancellation not supported on this operating system")
        }
        
      } catch {
        print("error setting audio session category: \(error.localizedDescription)")
      }
    }
  }
}
