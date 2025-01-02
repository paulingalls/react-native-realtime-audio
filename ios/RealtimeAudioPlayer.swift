import Foundation
import AVFoundation

protocol RealtimeAudioPlayerDelegate: AnyObject {
    func audioPlayerDidStartPlaying()
    func audioPlayerDidStopPlaying()
}

class RealtimeAudioPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let inputFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat
    private let audioConverter: AVAudioConverter
    private var bufferQueue: [AVAudioPCMBuffer] = []
    private var currentInputBuffer: AVAudioPCMBuffer?
    private var currentInputBufferOffset: UInt32 = 0
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
    
    init?(sampleRate: Double, channels: UInt32 = 1, bitsPerChannel: Int = 16) {
        guard let inputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: sampleRate,
                                         channels: channels,
                                         interleaved: false
        ) else {
            return nil
        }
        self.inputFormat = inputFormat
        self.outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        print("inputFormat: \(self.inputFormat.sampleRate), \(self.inputFormat.channelCount), \(self.inputFormat.isInterleaved), \(self.inputFormat.isStandard)")
        print("outputFormat: \(self.outputFormat.sampleRate), \(self.outputFormat.channelCount), \(self.outputFormat.isInterleaved), \(self.outputFormat.isStandard)")
        self.audioConverter = AVAudioConverter(from: self.inputFormat, to: self.outputFormat)!
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: outputFormat)
        
        do {
            try engine.start()
        } catch {
            print("Error starting audio engine: \(error.localizedDescription)")
        }
    }
    
    func addBuffer(_ base64EncodedString: String) {
        guard let data = Data(base64Encoded: base64EncodedString) else {
            print("Error: Invalid base64 string")
            return
        }
        
        do {
            let buffer = try createBuffer(from: data)
            
            bufferQueue.append(buffer)
            checkAndStartPlayback()
        } catch {
            print("Error creating buffer: \(error.localizedDescription)")
        }
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
        guard !isPlaying, !bufferQueue.isEmpty else { return }
        isPlaying = true
        startPlayingNextBuffer()
    }
    
    private func startPlayingNextBuffer() {
        guard !bufferQueue.isEmpty else {
            isPlaying = false
            return
        }
        
        if currentInputBuffer == nil {
            currentInputBuffer = bufferQueue.removeFirst()
            currentInputBufferOffset = 0
        }
        
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: currentInputBuffer!.frameLength)!
        
        var error: NSError?
        audioConverter.convert(to: outputBuffer, error: &error) { numSamplesNeeded, outStatus in
            let numSamplesAvailable = self.currentInputBuffer!.frameLength - self.currentInputBufferOffset
            let samplesToCopy = min(numSamplesAvailable, numSamplesNeeded)
            
            let tempBuffer = AVAudioPCMBuffer(pcmFormat: self.currentInputBuffer!.format,
                                              frameCapacity: samplesToCopy)!
            tempBuffer.frameLength = samplesToCopy
            
            let bytesPerFrame = self.currentInputBuffer!.format.streamDescription.pointee.mBytesPerFrame
            let sourceOffset = self.currentInputBufferOffset * UInt32(bytesPerFrame)
            let sourceData = self.currentInputBuffer!.audioBufferList.pointee.mBuffers
            let destData = tempBuffer.audioBufferList.pointee.mBuffers
            
            destData.mData?.copyMemory(from: sourceData.mData!.advanced(by: Int(sourceOffset)),
                                     byteCount: Int(samplesToCopy * bytesPerFrame))
            
            self.currentInputBufferOffset += samplesToCopy
            
            if samplesToCopy < numSamplesNeeded {
                self.currentInputBuffer = self.bufferQueue.removeFirst()
                self.currentInputBufferOffset = 0
            }
            outStatus.pointee = .haveData
            return tempBuffer
        }

        playerNode.scheduleBuffer(outputBuffer, at: nil) { [weak self] in
            self?.startPlayingNextBuffer()
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    func stop() {
        playerNode.stop()
        bufferQueue.removeAll()
        isPlaying = false
    }
    
    func pause() {
        playerNode.pause()
        isPlaying = false
    }
    
    func resume() {
        if !bufferQueue.isEmpty {
            isPlaying = true
            if !playerNode.isPlaying {
                startPlayingNextBuffer()
            }
        }
    }
    
    deinit {
        engine.stop()
    }
}
