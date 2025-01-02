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
    private let playbackQueue = DispatchQueue(label: "com.audioplayback.queue")
    
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
            playbackQueue.async { [weak self] in
                self?.bufferQueue.append(buffer)
                self?.checkAndStartPlayback()
            }
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
        
        let inputBuffer = bufferQueue.removeFirst()
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: inputBuffer.frameLength)!
        
        var error: NSError?
        audioConverter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }

        playerNode.scheduleBuffer(outputBuffer, at: nil) { [weak self] in
            self?.playbackQueue.async {
                self?.startPlayingNextBuffer()
            }
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    func stop() {
        playbackQueue.async { [weak self] in
            self?.playerNode.stop()
            self?.bufferQueue.removeAll()
            self?.isPlaying = false
        }
    }
    
    func pause() {
        playbackQueue.async { [weak self] in
            self?.playerNode.pause()
            self?.isPlaying = false
        }
    }
    
    func resume() {
        playbackQueue.async { [weak self] in
            guard let self = self else { return }
            if !bufferQueue.isEmpty {
                self.isPlaying = true
                if !self.playerNode.isPlaying {
                    self.startPlayingNextBuffer()
                }
            }
        }
    }
    
    deinit {
        engine.stop()
    }
}
