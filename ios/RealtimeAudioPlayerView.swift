import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioPlayerView: ExpoView {
    private var audioPlayer: RealtimeAudioPlayer?
    private var visualization: AudioVisualization
    private var sampleCount = 200
    
    let onPlaybackStarted = EventDispatcher()
    let onPlaybackStopped = EventDispatcher()

    public required init(appContext: AppContext? = nil) {
        self.visualization = WaveformVisualization(sampleCount: sampleCount)
        super.init(appContext: appContext)

        layer.addSublayer(visualization.layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        visualization.setFrame(bounds)
    }
    
    func setAudioFormat(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32) {
        audioPlayer = RealtimeAudioPlayer(
            sampleRate: sampleRate,
            commonFormat: commonFormat,
            channels: channels
        )
        audioPlayer?.delegate = self
    }

    func addBuffer(_ base64String: String) {
        audioPlayer?.addBuffer(base64String)
    }

    func resume() {
        audioPlayer?.resume()
    }

    func pause() {
        audioPlayer?.pause()
    }

    func stop() {
        audioPlayer?.stop()
    }

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

extension RealtimeAudioPlayerView: RealtimeAudioPlayerDelegate {
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
