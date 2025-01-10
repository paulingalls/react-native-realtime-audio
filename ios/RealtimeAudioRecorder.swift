import AVFoundation
import ExpoModulesCore

protocol RealtimeAudioRecorderDelegate: AnyObject {
    func audioRecorder(_ recorder: RealtimeAudioRecorder, didCaptureAudioData: String)
    func bufferCaptured(_ buffer: AVAudioPCMBuffer)
}

class RealtimeAudioRecorder: SharedObject, @unchecked Sendable {
    private var audioEngine: AVAudioEngine
    private var inputNode: AVAudioInputNode
    private let outputFormat: AVAudioFormat
    private var isRecording: Bool = false
     
    init?(sampleRate: Double = 24000,
          channelCount: UInt32 = 1,
          audioFormat: AVAudioCommonFormat = .pcmFormatInt16) {
        guard let outputFormat = AVAudioFormat(commonFormat: audioFormat,
                                               sampleRate: sampleRate,
                                               channels: AVAudioChannelCount(channelCount),
                                               interleaved: true
        ) else {
            return nil
        }
        self.audioEngine = AVAudioEngine()
        self.outputFormat = outputFormat
        self.inputNode = audioEngine.inputNode
    }
    
    weak var delegate: RealtimeAudioRecorderDelegate?
    
    func startRecording() throws {
        isRecording = true
        let semaphore = DispatchSemaphore(value: 0)
        let inputFormat = inputNode.outputFormat(forBus: 0)
        print("Input format: \(inputFormat.sampleRate), \(inputFormat.channelCount), \(inputFormat.commonFormat)")
        let audioConvertor = RealtimeAudioConverter(inputFormat: inputFormat, outputFormat: outputFormat, frameSize: 1200)!
        
        let tapBlock: AVAudioNodeTapBlock = { (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
            audioConvertor.addBuffer(buffer)
            self.delegate?.bufferCaptured(buffer)
            semaphore.signal()
        }
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(1)) {
            while self.isRecording {
                semaphore.wait()
                let outputBuffer = audioConvertor.getNextBuffer()
                if outputBuffer == nil {
                    continue
                }
                let frameLength = Int(outputBuffer!.frameLength)
                let audioData: Data
                
                switch self.outputFormat.commonFormat {
                case .pcmFormatFloat32:
                    if let channelData = outputBuffer!.floatChannelData?[0] {
                        audioData = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
                    } else {
                        return
                    }
                    
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
                    
                case .pcmFormatFloat64:
                    return
                    
                case .otherFormat:
                    return
                    
                @unknown default:
                    return
                }
                
                let base64String = audioData.base64EncodedString()
                
                // Provide data to delegate on main thread
                DispatchQueue.main.async {
                    self.delegate?.audioRecorder(self, didCaptureAudioData: base64String)
                }
            }
        }
        
        do {
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat, block: tapBlock)
            try audioEngine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        isRecording = false
        audioEngine.stop()
        inputNode.removeTap(onBus: 0)
    }
    
    deinit {
        stopRecording()
    }
}
