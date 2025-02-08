import ExpoModulesCore
import SwiftUI
import AVFoundation

public class BaseAudioView: ExpoView {
  var visualization: AudioVisualization
  var echoCancellationEnabled: Bool = false
  let visualizerQueue = DispatchQueue(label: "os.react-native-real-time-audio.visualization", qos: .userInteractive)
  
  public required init(appContext: AppContext? = nil) {
    self.visualization = BarGraphVisualizer()
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
    if samplePieces.isEmpty { return }
    
    let sampleRate = Float(buffer.format.sampleRate)
    let sampleCount = samplePieces[0].count
    
    // Calculate the duration of each piece
    let pieceDuration = Float(sampleCount) / sampleRate
    
    for (index, samples) in samplePieces.enumerated() {
      let delay = Double(Float(index) * pieceDuration)
      
      visualizerQueue.asyncAfter(deadline: .now() + delay) { [weak self] in
        DispatchQueue.main.async {
          self?.visualization.updateVisualization(with: samples)
        }
      }
    }
  }
  
}
