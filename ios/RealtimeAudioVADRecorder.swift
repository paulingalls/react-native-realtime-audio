import AVFoundation
import ExpoModulesCore

protocol RealtimeAudioVADRecorderDelegate: AnyObject {
  func base64VoiceBufferReady(_ base64Audio: String)
  func voiceBufferCaptured(_ buffer: AVAudioPCMBuffer)
  func voiceDidStart()
  func voiceDidStop()
}

class RealtimeAudioVADRecorder: SharedObject, @unchecked Sendable {
  private var audioEngine: AVAudioEngine
  private var inputNode: AVAudioInputNode
  private let outputFormat: AVAudioFormat
  private let vad: VadIterator
  private var bufferCache: [AVAudioPCMBuffer] = []
  private var waitTimeout: Int = 26
  private var voiceSpeaking: Bool = false
  
  weak var delegate: RealtimeAudioVADRecorderDelegate?
  public var echoCancellationEnabled: Bool = false
  
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
    
    let bundleURL = Bundle.main.url(forResource:"RealtimeAudio", withExtension: "bundle")
    let onnxBundle = Bundle(url: bundleURL!)
    let onnxModelURL = onnxBundle!.url(forResource: "silero_vad_16k_op15", withExtension: "onnx")!
    let modelPath = onnxModelURL.absoluteString.replacingOccurrences(of: "file://", with: "")
    self.vad = VadIterator(modelPath: modelPath,
                           sampleRate: 16000,
                           frameSize: 32,
                           threshold: 0.5,
                           minSilenceDurationMs: 960)
  }
  
  fileprivate func handleEchoCancellation() {
    if self.echoCancellationEnabled {
      do {
        try inputNode.setVoiceProcessingEnabled(true)
        try audioEngine.outputNode.setVoiceProcessingEnabled(true)
      } catch {
        print("Error setting voice processing enabled: \(error.localizedDescription)")
      }
    }
  }
  
  func startListening() {
    voiceSpeaking = false
    let inputFormat = inputNode.outputFormat(forBus: 0)
    let voiceConverter = RealtimeAudioConverter(inputFormat: inputFormat,
                                                outputFormat: outputFormat,
                                                frameSize: 2400)!
    let vadFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                  sampleRate: 16000,
                                  channels: 1,
                                  interleaved: false)!
    let vadConverter = RealtimeAudioConverter(inputFormat: inputFormat,
                                              outputFormat: vadFormat,
                                              frameSize: 512)!
    let vadTapQueue = DispatchQueue(label: "os.react-native-real-time-audio.vadTapQueue")
    let tapBlock: AVAudioNodeTapBlock = { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
      vadTapQueue.async {
        print("add vad buffer")
        vadConverter.addBuffer(buffer)
        let depth = vadConverter.getDepth()
        if depth > 10 {
          self.waitTimeout = 22
        } else if depth < 5 {
          self.waitTimeout = 30
        } else {
          self.waitTimeout = 26
        }
        
        if self.voiceSpeaking {
          print("add voice buffer")
          self.delegate?.voiceBufferCaptured(buffer)
          voiceConverter.addBuffer(buffer)
        } else {
          self.bufferCache.append(buffer)
          if self.bufferCache.count > 8 {
            self.bufferCache.removeFirst()
          }
        }
      }
    }
    
    handleEchoCancellation()
    
    do {
      inputNode.installTap(onBus: 0, bufferSize: 4800, format: inputFormat, block: tapBlock)
      try audioEngine.start()
    } catch {
      print("Error starting audio engine: \(error.localizedDescription)")
    }
    
    let yield = DispatchSemaphore(value: 0)
    let vadCheckQueue = DispatchQueue(label: "os.react-native-real-time-audio.vadCheckQueue")
    vadCheckQueue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(200)) {
      while true {
        let _ = yield.wait(timeout: DispatchTime.now() + DispatchTimeInterval.milliseconds(self.waitTimeout))
        let outputBuffer = vadConverter.getNextBuffer()
        print("got vad buffer")
        if outputBuffer == nil || outputBuffer!.frameLength < 512 {
          if (!self.voiceSpeaking) {
            DispatchQueue.main.async {
              self.delegate?.voiceDidStop()
            }
            break
          }
          print("didn't get a buffer in time, bailing out...")
          break
        }
        
        let frameLength = Int(outputBuffer!.frameLength)
        let byteCount = frameLength * MemoryLayout<Float32>.stride
        let data = NSMutableData(capacity: byteCount)!
        data.append(outputBuffer!.floatChannelData![0], length: byteCount)
        let hasVoice = try! self.vad.predict(data: data)
        if hasVoice {
          if !self.voiceSpeaking {
            self.voiceSpeaking = true
            self.bufferCache.forEach { buffer in
              voiceConverter.addBuffer(buffer)
            }
            self.bufferCache.removeAll()
            
            DispatchQueue.main.async {
              self.delegate?.voiceDidStart()
            }
            
            let recordingQueue = DispatchQueue(label: "os.react-native-real-time-audio.vadRecordingQueue")
            recordingQueue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(200)) {
              while self.voiceSpeaking {
                let _ = yield.wait(timeout: DispatchTime.now() + DispatchTimeInterval.milliseconds(100))
                let outputBuffer = voiceConverter.getNextBuffer()
                print("got voice buffer")
                if outputBuffer == nil {
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
                  self.delegate?.base64VoiceBufferReady(base64String)
                }
              }
            }
          }
        } else {
          if self.voiceSpeaking {
            self.voiceSpeaking = false
            voiceConverter.clear()
            DispatchQueue.main.async {
              self.delegate?.voiceDidStop()
            }
          }
        }
      }
    }
  }

  func stopListening() {
    audioEngine.stop()
    inputNode.removeTap(onBus: 0)
    if voiceSpeaking {
      voiceSpeaking = false
      DispatchQueue.main.async {
        self.delegate?.voiceDidStop()
      }
    }
    audioEngine.reset()
    vad.resetState()
  }
  
  deinit {
    stopListening()
  }
  
}
