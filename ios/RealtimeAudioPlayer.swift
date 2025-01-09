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
    
    init?(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32 = 1, interleaved: Bool = false) {
        guard let inputFormat = AVAudioFormat(commonFormat: commonFormat,
                                              sampleRate: sampleRate,
                                              channels: AVAudioChannelCount(channels),
                                              interleaved: interleaved
        ) else {
            return nil
        }
        let mixerOutputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let outputFormat = AVAudioFormat(commonFormat: mixerOutputFormat.commonFormat,
                                         sampleRate: 48000,
                                         channels: mixerOutputFormat.channelCount,
                                         interleaved: mixerOutputFormat.isInterleaved)!
        self.inputFormat = inputFormat
        self.outputFormat = outputFormat
        self.converter = RealtimeAudioConverter(inputFormat: inputFormat, outputFormat: outputFormat)!
        super.init()
        setupAudioEngine()
    }
    
    public func addBuffer(_ base64EncodedString: String) {
        guard let data = Data(base64Encoded: base64EncodedString) else {
            print("Error: Invalid base64 string")
            return
        }
        
        do {
            let buffer = try createBuffer(from: data)
            converter.addBuffer(buffer)
            checkAndStartPlayback()
        } catch {
            print("Error creating buffer: \(error.localizedDescription)")
        }
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
        guard !isPlaying, !converter.isEmpty() else { return }
        isPlaying = true
        startPlayingNextBuffer()
    }
    
    private func startPlayingNextBuffer() {
        let outputBuffer = converter.getNextBuffer()
        if outputBuffer == nil {
            isPlaying = false
            return
        }
        
        playerNode.scheduleBuffer(outputBuffer!, at: nil) { [weak self] in
            self?.startPlayingNextBuffer()
        }
        
        delegate?.audioPlayerBufferDidBecomeAvailable(outputBuffer!)
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    func stop() {
        playerNode.stop()
        converter.clear()
        isPlaying = false
    }
    
    func pause() {
        playerNode.pause()
        isPlaying = false
    }
    
    func resume() {
        if !converter.isEmpty() {
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
