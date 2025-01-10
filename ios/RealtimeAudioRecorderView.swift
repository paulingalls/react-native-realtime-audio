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
    
    // Audio format properties
    private var sampleRate: Double = 24000
    private var commonFormat: AVAudioCommonFormat = .pcmFormatInt16
    private var channels: UInt32 = 1
    
    let onAudioCaptured = EventDispatcher()

    
    public required init(appContext: AppContext? = nil) {
        self.visualization = WaveformVisualization(sampleCount: sampleCount)
        super.init(appContext: appContext)
        setupVisualization()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAudioRecorder() {
        audioRecorder = RealtimeAudioRecorder(sampleRate: sampleRate, channelCount: channels, audioFormat: commonFormat)
        audioRecorder?.delegate = self
    }

    private func setupVisualization() {
        layer.addSublayer(visualization.layer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        visualization.setFrame(bounds)
    }

    @objc
    func startRecording() {
        do {
            try audioRecorder?.startRecording()
        } catch {
            print("Error starting recording: \(error.localizedDescription)")
        }
    }

    @objc
    func stopRecording() {
        audioRecorder?.stopRecording()
    }
    
    @objc
    func setAudioFormat(sampleRate: Double, commonFormat: AVAudioCommonFormat, channels: UInt32) {
        self.sampleRate = sampleRate
        self.commonFormat = commonFormat
        self.channels = channels

        // Recreate audio player with new settings
        setupAudioRecorder()
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

extension RealtimeAudioRecorderView: RealtimeAudioRecorderDelegate {
    func audioRecorder(_ recorder: RealtimeAudioRecorder, didCaptureAudioData: String) {
        let event = ["audioBuffer": didCaptureAudioData]
        onAudioCaptured(event)
    }
    
    func bufferCaptured(_ buffer: AVAudioPCMBuffer) {
        updateVisualizationSamples(from: buffer)
    }
}
