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
    private var bitsPerSample: Int = 16
    private var channels: UInt32 = 1
    
    private let onPlaybackStart = EventDispatcher()
    private let onPlaybackStop = EventDispatcher()

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
            channels: channels,
            bitsPerChannel: bitsPerSample
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
        guard let data = Data(base64Encoded: base64String) else { return }
        updateWaveformSamples(from: data)
        audioPlayer?.addBuffer(base64String)
    }

    @objc
    func play() {
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
    func setAudioFormat(sampleRate: Double, bitsPerSample: Int, channels: UInt32) {
        self.sampleRate = sampleRate
        self.bitsPerSample = bitsPerSample
        self.channels = channels

        // Recreate audio player with new settings
        setupAudioPlayer()
    }

    @objc
    func setWaveformColor(_ hexColor: String) {
        let color = UIColor(hex: hexColor) ?? .blue
        waveformLayer.strokeColor = color.cgColor
    }

    private func updateWaveformSamples(from data: Data) {
        let samples = data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) -> [Float] in
            let shorts = rawBufferPointer.bindMemory(to: Int16.self).baseAddress!
            let count = data.count / MemoryLayout<Int16>.size
            let strideLength = max(1, count / sampleCount)
            
            var samples: [Float] = []
            for i in stride(from: 0, to: count, by: strideLength) {
                let sample = abs(Float(shorts[i]) / Float(Int16.max))
                samples.append(sample)
            }
            
            while samples.count > sampleCount {
                samples.removeLast()
            }
            while samples.count < sampleCount {
                samples.append(0)
            }
            
            return samples
        }
        
        currentSamples = samples
        DispatchQueue.main.async { [weak self] in
            self?.updateWaveformPath()
        }
    }
    
    public func sendPlaybackStartEvent() {
        onPlaybackStart()
    }
    
    public func sendPlaybackStopEvent() {
        onPlaybackStop()
    }
}

extension RealtimeAudioView: RealtimeAudioPlayerDelegate {
    func audioPlayerDidStartPlaying() {
        sendPlaybackStartEvent()
    }

    func audioPlayerDidStopPlaying() {
        sendPlaybackStopEvent()
    }
}

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b: CGFloat

        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat(hexNumber & 0x0000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: 1.0)
                    return
                }
            }
        }
        return nil
    }
}
