import UIKit
import AVFoundation

public class BaseVisualizer: AudioVisualization {
  private(set) var layer: CALayer
  let shapeLayer = CAShapeLayer()
  var mainColor: UIColor = .systemBlue
  var chunkSize: Int = 800

  init() {
    self.layer = CALayer()
    self.layer.addSublayer(shapeLayer)
  }
  
  func setColor(_ color: UIColor) {
    mainColor = color
  }
  
  func setFrame(_ frame: CGRect) {
    shapeLayer.frame = frame
  }
  
  func clearVisualization() {
    shapeLayer.path = nil
  }

  func updateVisualization(with samples: [Float]) {}
  
  func getSamplesFromAudio(_ audio: AVAudioPCMBuffer) -> [[Float]] {
    guard let channelData = audio.floatChannelData else { return [] }
    let frameLength = Int(audio.frameLength)
    
    if audio.format.channelCount > 0 {
      let channelSamples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
      return breakIntoChunks(channelSamples, chunkSize: chunkSize)
    }
    
    return []
  }
  
  private func breakIntoChunks(_ samples: [Float], chunkSize: Int) -> [[Float]] {
    var chunks: [[Float]] = []
    var currentIndex = 0
    
    while currentIndex < samples.count {
      let endIndex = min(currentIndex + chunkSize, samples.count)
      let chunk = Array(samples[currentIndex..<endIndex])
      chunks.append(chunk)
      currentIndex = endIndex
    }
    
    return chunks
  }

}
