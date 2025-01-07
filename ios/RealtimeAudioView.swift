import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioView: ExpoView {
    private var audioPlayer: RealtimeAudioPlayer?
    private let waveformLayer = CAShapeLayer()
    private var sampleCount = 100
    private var waveformColor: UIColor = .blue

    // Audio format properties
    private var sampleRate: Double = 24000
    private var commonFormat: AVAudioCommonFormat = .pcmFormatInt16
    private var channels: UInt32 = 1
    private var interleaved: Bool = false
    
    let onPlaybackStart = EventDispatcher()
    let onPlaybackStop = EventDispatcher()

    public required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        setupWaveformLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAudioPlayer() {
        // Recreate audio player with current format settings
        audioPlayer = RealtimeAudioPlayer(
            sampleRate: sampleRate,
            commonFormat: commonFormat,
            channels: channels,
            interleaved: interleaved
        )
        audioPlayer?.delegate = self
    }

    private func setupWaveformLayer() {
        waveformLayer.strokeColor = waveformColor.cgColor
        waveformLayer.fillColor = nil
        waveformLayer.lineWidth = 2.0
        layer.addSublayer(waveformLayer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        waveformLayer.frame = bounds
        updateWaveformPath()
    }

    private func updateWaveformPath() {
        guard let samples = currentSamples else { return }

        let path = UIBezierPath()
        let width = bounds.width
        let height = bounds.height
        let midPoint = height / 2
        let sampleWidth = width / CGFloat(samples.count)

        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * sampleWidth
            let sampleHeight = CGFloat(sample) * height

            path.move(to: CGPoint(x: x, y: midPoint - sampleHeight/2))
            path.addLine(to: CGPoint(x: x, y: midPoint + sampleHeight/2))
        }

        waveformLayer.path = path.cgPath
    }

    private var currentSamples: [Float]?

    // MARK: - Public Methods

    @objc
    func addBuffer(_ base64String: String) {
        audioPlayer?.addBuffer(base64String)
    }

    @objc
    func resume() {
        audioPlayer?.resume()
    }

    @objc
    func pause() {
        audioPlayer?.pause()
    }

    @objc
    func stop() {
        audioPlayer?.stop()
    }

    // MARK: - Configuration Methods

    @objc
    func setAudioFormat(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32, interleaved: Bool) {
        self.sampleRate = sampleRate
        self.commonFormat = commonFormat
        self.channels = channels
        self.interleaved = interleaved

        // Recreate audio player with new settings
        setupAudioPlayer()
    }

    @objc
    func setWaveformColor(_ hexColor: UIColor) {
        waveformLayer.strokeColor = hexColor.cgColor
    }

    private func updateWaveformSamples(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else {
            print("Error: Could not access float channel data")
            return
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        let strideLength = max(1, frameLength / sampleCount)
        
        var samples: [Float] = []
        
        for i in stride(from: 0, to: frameLength, by: strideLength) {
            var sample: Float = 0
            for channel in 0..<channelCount {
                sample += abs(channelData[channel][i])
            }
            sample /= Float(channelCount)
            samples.append(sample)
        }
        
        // Adjust sample count if necessary
        while samples.count > sampleCount {
            samples.removeLast()
        }
        while samples.count < sampleCount {
            samples.append(0)
        }
        
        currentSamples = samples
        DispatchQueue.main.async { [weak self] in
            self?.updateWaveformPath()
        }
    }
}

extension RealtimeAudioView: RealtimeAudioPlayerDelegate {
    func audioPlayerDidStartPlaying() {
        onPlaybackStart()
    }
    
    func audioPlayerDidStopPlaying() {
        onPlaybackStop()
    }
    
    func audioPlayerBufferDidBecomeAvailable(_ buffer: AVAudioPCMBuffer) {
        updateWaveformSamples(from: buffer)
    }
}
