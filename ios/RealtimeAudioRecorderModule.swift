import AVFoundation
import ExpoModulesCore

public class RealtimeAudioRecorderModule: Module, RealtimeAudioRecorderDelegate {
    var hasListeners: Bool = false
    
    public func definition() -> ModuleDefinition {
        Name("RealtimeAudioRecorder")
        
        Events("onAudioCaptured")
        
        OnStartObserving {
            hasListeners = true
        }
        
        OnStopObserving {
            hasListeners = false
        }
        
        Class(RealtimeAudioRecorder.self) {
            Constructor { (audioFormat: AudioFormatSettings) -> RealtimeAudioRecorder in
                let recorder: RealtimeAudioRecorder = RealtimeAudioRecorder(sampleRate: audioFormat.sampleRate,
                                                                            channelCount: audioFormat.channelCount,
                                                                            audioFormat: getCommonFormat(audioFormat.encoding))!
                recorder.delegate = self
                return recorder
            }
            
            AsyncFunction("startRecording") { (recorder: RealtimeAudioRecorder) in
                do {
                    try recorder.startRecording()
                } catch {
                    print("Error starting recording: \(error.localizedDescription)")
                }
            }

            AsyncFunction("stopRecording") { (recorder: RealtimeAudioRecorder) in
                recorder.stopRecording()
            }
        }
        
        View(RealtimeAudioRecorderView.self) {
            Events("onAudioCaptured")
            
            Prop("waveformColor") { (
                view: RealtimeAudioRecorderView,
                hexColor: UIColor
            ) in
                view.setWaveformColor(hexColor)
            }
            
            Prop("audioFormat") { (
                view: RealtimeAudioRecorderView,
                format: AudioFormatSettings
            ) in
                view.setAudioFormat(
                        sampleRate: format.sampleRate,
                        commonFormat: self.getCommonFormat(format.encoding),
                        channels: format.channelCount
                    )
            }
            
            AsyncFunction("startRecording") { (view: RealtimeAudioRecorderView) in
                view.startRecording()
            }
            
            AsyncFunction("stopRecording") { (view: RealtimeAudioRecorderView) in
                view.stopRecording()
            }
        }
    }

    func audioRecorder(_ recorder: RealtimeAudioRecorder, didCaptureAudioData: String) {
        if (hasListeners) {
            let event = ["audioBuffer": didCaptureAudioData]
            sendEvent("onAudioCaptured", event)
        }
    }

    func bufferCaptured(_ buffer: AVAudioPCMBuffer) {
    }
    
    private func getCommonFormat(_ encoding: AudioEncoding) -> AVAudioCommonFormat {
        switch encoding {
        case .pcm16bitInteger:
            return .pcmFormatInt16
        case .pcm32bitInteger:
            return .pcmFormatInt32
        case .pcm32bitFloat:
            return .pcmFormatFloat32
        case .pcm64bitFloat:
            return .pcmFormatFloat64
        }
    }
    
}
