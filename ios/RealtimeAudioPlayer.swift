import Foundation
import AVFoundation
import ExpoModulesCore

protocol RealtimeAudioPlayerDelegate: AnyObject {
    func audioPlayerDidStartPlaying()
    func audioPlayerDidStopPlaying()
    func audioPlayerBufferDidBecomeAvailable(_ buffer: AVAudioPCMBuffer)
}

class RealtimeAudioPlayer: SharedObject {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let inputFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat
    private let converter: RealtimeAudioConverter
    private var bufferQueue: [AVAudioPCMBuffer] = []
    private let queueReady = DispatchSemaphore(value: 0)
    private let converterDispatchQueue = DispatchQueue(label: "os.react-native-real-time-audio.converter-queue")
    private let playerDispatchQueue = DispatchQueue(label: "os.react-native-real-time-audio.player-queue")
    private let playerReady = DispatchSemaphore(value: 0)
    private var isStopping = false
    private var isEngineSetup = false

    private var isPlaying = false {
        didSet {
            if isPlaying != oldValue {
                if isPlaying {
                    delegate?.audioPlayerDidStartPlaying()
                } else {
                    delegate?.audioPlayerDidStopPlaying()
                }
            }
        }
    }
    
    weak var delegate: RealtimeAudioPlayerDelegate?
    
    init?(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32 = 1) {
        guard let inputFormat = AVAudioFormat(commonFormat: commonFormat,
                                              sampleRate: sampleRate,
                                              channels: AVAudioChannelCount(channels),
                                              interleaved: true
        ) else {
            return nil
        }
        let mixerOutputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let outputFormat = AVAudioFormat(commonFormat: mixerOutputFormat.commonFormat,
                                         sampleRate: 48000,
                                         channels: 1,
                                         interleaved: true)!
        self.inputFormat = inputFormat
        self.outputFormat = outputFormat
        self.converter = RealtimeAudioConverter(inputFormat: inputFormat, outputFormat: outputFormat, frameSize: 48000)!
        super.init()
        print("RealtimeAudioPlayer initialized")
    }
    
    public func addBuffer(_ base64EncodedString: String) {
        guard !isStopping else {
            return;
        }
        guard let data = Data(base64Encoded: base64EncodedString) else {
            print("Error: Invalid base64 string")
            return
        }
        
        do {
            let buffer = try createBuffer(from: data)
            converter.addBuffer(buffer)
            print("added buffer \(buffer.frameLength)")
            checkAndStartPlayback()
        } catch {
            print("Error creating buffer: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioEngine() {
        guard !isEngineSetup else {
          return
        }
      
//        do {
//          print("initial input format: \(engine.inputNode.outputFormat(forBus: 0))")
//          try engine.inputNode.setVoiceProcessingEnabled(true)
//        } catch {
//          print("Error setting voice processing enabled: \(error.localizedDescription)")
//        }

        playerNode.volume = 1.0
        print("output format: \(outputFormat.sampleRate) \(outputFormat.channelCount) \(outputFormat.commonFormat)")
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: outputFormat)
        engine.prepare()
        isEngineSetup = true
    }
    
    private func createBuffer(from data: Data) throws -> AVAudioPCMBuffer {
        let frameCount = UInt32(data.count) / inputFormat.streamDescription.pointee.mBytesPerFrame
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioPlayerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not create audio buffer"])
        }
        
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            audioBuffer.mData?.copyMemory(from: bytes.baseAddress!, byteCount: Int(audioBuffer.mDataByteSize))
        }
        
        return buffer
    }
    
    private func checkAndStartPlayback() {
        guard !isPlaying, converter.isReady() else { return }
        setupAudioEngine()
        
        print("Starting playback")

        isPlaying = true
        converterDispatchQueue.async {
            while !self.isStopping {
                self.playerReady.wait()
                let outputBuffer = self.converter.getNextBuffer()
                print("got next buffer from converter \(outputBuffer?.frameLength ?? 0)")
                if outputBuffer == nil {
                    self.stop()
                    self.queueReady.signal();
                    break
                }
                self.bufferQueue.append(outputBuffer!)
                self.queueReady.signal()
            }
        }
        playerDispatchQueue.async {
            while true {
                self.queueReady.wait()
                if self.isStopping {
                    break
                }
                
                if self.bufferQueue.isEmpty {
                    self.playerReady.signal();
                    continue
                }
                let outputBuffer: AVAudioPCMBuffer! = self.bufferQueue.removeFirst()
                self.playerNode.scheduleBuffer(outputBuffer!, at: nil) { [weak self] in
                    self?.playerReady.signal()
                }
                self.delegate?.audioPlayerBufferDidBecomeAvailable(outputBuffer)
            }
        }
        
        do {
            try engine.start()
            playerNode.play()
            playerReady.signal()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
        
    func stop() {
        isStopping = true
        self.playerNode.stop()
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + DispatchTimeInterval.seconds(1)) {
            self.isStopping = false
            self.engine.stop()
            self.engine.reset()
            self.converter.clear()
            self.bufferQueue.removeAll()
            self.isPlaying = false
        }
    }
    
    func pause() {
        playerNode.isPlaying ? playerNode.pause() : ()
    }
    
    func resume() {
        playerNode.isPlaying ? () : playerNode.play()
    }
    
    deinit {
      print("RealTimeAudioPlayer deinit")
        engine.stop()
        engine.reset()
        converter.clear()
    }
}
