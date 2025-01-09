import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioView: ExpoView {
    private var audioPlayer: RealtimeAudioPlayer?
    private var visualization: AudioVisualization
    private var sampleCount = 200

    // Audio format properties
    private var sampleRate: Double = 24000
    private var commonFormat: AVAudioCommonFormat = .pcmFormatInt16
    private var channels: UInt32 = 1
    private var interleaved: Bool = false
    
    let onPlaybackStarted = EventDispatcher()
    let onPlaybackStopped = EventDispatcher()

    public required init(appContext: AppContext? = nil) {
        self.visualization = WaveformVisualization(sampleCount: sampleCount)
        super.init(appContext: appContext)
        setupVisualization()
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

    private func setupVisualization() {
        layer.addSublayer(visualization.layer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        visualization.setFrame(bounds)
    }
    
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
        visualization.setColor(hexColor)
    }

    private func updateVisualizationSamples(from buffer: AVAudioPCMBuffer) {
        let samples = self.visualization.getSamplesFromAudio(buffer)
        DispatchQueue.main.async { [weak self] in
            self?.visualization.updateVisualization(with: samples)
        }
    }
}

extension RealtimeAudioView: RealtimeAudioPlayerDelegate {
    func audioPlayerDidStartPlaying() {
        onPlaybackStarted()
    }
    
    func audioPlayerDidStopPlaying() {
        onPlaybackStopped()
    }
    
    func audioPlayerBufferDidBecomeAvailable(_ buffer: AVAudioPCMBuffer) {
        updateVisualizationSamples(from: buffer)
    }
}
