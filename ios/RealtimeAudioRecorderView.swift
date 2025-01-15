//
//  RealtimeAudioRecorderView.swift
//  Pods
//
//  Created by Paul Ingalls on 1/9/25.
//

import ExpoModulesCore
import SwiftUI
import AVFoundation

public class RealtimeAudioRecorderView: ExpoView {
    private var audioRecorder: RealtimeAudioRecorder?
    private var visualization: AudioVisualization
    private var sampleCount = 200
    
    let onAudioCaptured = EventDispatcher()
    let onCaptureComplete = EventDispatcher()
    
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
        audioRecorder = RealtimeAudioRecorder(sampleRate: sampleRate, channelCount: channels, audioFormat: commonFormat)
        audioRecorder?.delegate = self
    }

    func startRecording() {
        do {
            try audioRecorder?.startRecording()
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stopRecording()
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

extension RealtimeAudioRecorderView: RealtimeAudioRecorderDelegate {
    func base64BufferReady(_ base64Audio: String) {
        let event = ["audioBuffer": base64Audio]
        onAudioCaptured(event)
    }
    
    func bufferCaptured(_ buffer: AVAudioPCMBuffer) {
        updateVisualizationSamples(from: buffer)
    }
    
    func audioRecorderDidFinishRecording() {
        onCaptureComplete()
    }
}
