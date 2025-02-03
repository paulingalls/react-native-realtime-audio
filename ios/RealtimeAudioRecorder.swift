import AVFoundation
import ExpoModulesCore

protocol RealtimeAudioRecorderDelegate: AnyObject {
  func base64BufferReady(_ base64Audio: String)
  func bufferCaptured(_ buffer: AVAudioPCMBuffer)
  func audioRecorderDidFinishRecording()
}

class RealtimeAudioRecorder: SharedObject, @unchecked Sendable {
  private var audioEngine: AVAudioEngine
  private var inputNode: AVAudioInputNode
  private let outputFormat: AVAudioFormat
  private var isRecording: Bool = false
  private let recorderDispatchQueue = DispatchQueue(label: "os.react-native-real-time-audio.recorder-queue")
  private var waitTimeout: Int = 100

  
  init?(sampleRate: Double = 24000,
        channelCount: UInt32 = 1,
        audioFormat: AVAudioCommonFormat = .pcmFormatInt16) {
    guard let outputFormat = AVAudioFormat(commonFormat: audioFormat,
                                           sampleRate: sampleRate,
                                           channels: AVAudioChannelCount(channelCount),
                                           interleaved: false
    ) else {
      return nil
    }
    self.audioEngine = AVAudioEngine()
    self.outputFormat = outputFormat
    self.inputNode = audioEngine.inputNode
  }
  
  weak var delegate: RealtimeAudioRecorderDelegate?
  public var echoCancellationEnabled: Bool = false
  
  func startRecording() throws {
    let yield = DispatchSemaphore(value: 0)
    isRecording = true
    
    
    let inputFormat = inputNode.outputFormat(forBus: 0)
    print("inputFormat: \(inputFormat)")
    let audioConvertor = RealtimeAudioConverter(inputFormat: inputFormat,
                                                outputFormat: outputFormat,
                                                frameSize: 2400)!
    let tapQueue = DispatchQueue(label: "os.react-native-real-time-audio.tapQueue")
    let tapBlock: AVAudioNodeTapBlock = { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
      tapQueue.async {
        audioConvertor.addBuffer(buffer)
        let depth = audioConvertor.getDepth()
        if depth > 8 {
          self.waitTimeout = 70
        } else if depth < 4 {
          self.waitTimeout = 130
        } else {
          self.waitTimeout = 100
        }

        self.delegate?.bufferCaptured(buffer)
      }
    }
    
    if self.echoCancellationEnabled {
      do {
        try inputNode.setVoiceProcessingEnabled(true)
        try audioEngine.outputNode.setVoiceProcessingEnabled(true)
      } catch {
        print("Error setting voice processing enabled: \(error.localizedDescription)")
      }
    }
    
    do {
      inputNode.installTap(onBus: 0, bufferSize: 4800, format: inputFormat, block: tapBlock)
      try audioEngine.start()
    } catch {
      print("Error starting audio engine: \(error.localizedDescription)")
    }
    
    recorderDispatchQueue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(200)) {
      while true {
        let _ = yield.wait(timeout: DispatchTime.now() + DispatchTimeInterval.milliseconds(self.waitTimeout))
        let outputBuffer = audioConvertor.getNextBuffer()
        if outputBuffer == nil {
          if (!self.isRecording) {
            DispatchQueue.main.async {
              self.delegate?.audioRecorderDidFinishRecording()
            }
            break
          }
          print("didn't get a buffer in time, bailing out...")
          break
        }
        let frameLength = Int(outputBuffer!.frameLength)
        let audioData: Data
        
        switch self.outputFormat.commonFormat {
        case .pcmFormatInt16:
          if let channelData = outputBuffer!.int16ChannelData?[0] {
            audioData = Data(bytes: channelData, count: frameLength * MemoryLayout<Int16>.size)
          } else {
            return
          }
          
        case .pcmFormatInt32:
          if let channelData = outputBuffer!.int32ChannelData?[0] {
            audioData = Data(bytes: channelData, count: frameLength * MemoryLayout<Int32>.size)
          } else {
            return
          }
          
        case .pcmFormatFloat32:
          if let channelData = outputBuffer!.floatChannelData?[0] {
            audioData = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
          } else {
            return
          }
          
        case .pcmFormatFloat64:
          return
        case .otherFormat:
          return
        @unknown default:
          return
        }
        
        let base64String = audioData.base64EncodedString()
        
        DispatchQueue.main.async {
          self.delegate?.base64BufferReady(base64String)
        }
      }
    }
  }
  
  func stopRecording() {
    isRecording = false
    audioEngine.stop()
    inputNode.removeTap(onBus: 0)
    audioEngine.reset()
  }
  
  deinit {
    stopRecording()
  }
}
