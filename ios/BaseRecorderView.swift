import ExpoModulesCore
import SwiftUI
import AVFoundation

public class BaseRecorderView: ExpoView {
  var visualization: AudioVisualization
  var echoCancellationEnabled: Bool = false

  public required init(appContext: AppContext? = nil) {
    self.visualization = LinearWaveformVisualizer()
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
  
  func setVisualization(_ visualization: AudioVisualization) {
    layer.replaceSublayer(self.visualization.layer, with: visualization.layer)
    self.visualization = visualization
  }

  func setWaveformColor(_ hexColor: UIColor) {
    visualization.setColor(hexColor)
  }
  
  func updateVisualizationSamples(from buffer: AVAudioPCMBuffer) {
    let samplePieces = visualization.getSamplesFromAudio(buffer)
    let sampleRate = Float(buffer.format.sampleRate)
    let sampleCount = samplePieces[0].count
    
    // Calculate the duration of each piece
    let pieceDuration = Float(sampleCount) / sampleRate
    
    // Use DispatchQueue to schedule the updates
    let queue = DispatchQueue(label: "os.react-native-real-time-audio.recording-visualization", qos: .userInteractive)
    
    for (index, samples) in samplePieces.enumerated() {
      let delay = Double(Float(index) * pieceDuration)
      
      queue.asyncAfter(deadline: .now() + delay) { [weak self] in
        DispatchQueue.main.async {
          self?.visualization.updateVisualization(with: samples)
        }
      }
    }
  }

}
