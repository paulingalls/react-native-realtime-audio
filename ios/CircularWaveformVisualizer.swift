import UIKit
import AVFoundation

class CircularWaveformVisualizer: BaseVisualizer {
  private var rotation: CGFloat = 0
  private var colorShift: CGFloat = 0
    
  override func updateVisualization(with samples: [Float]) {
    guard let superlayer = layer.superlayer else { return }
    let width = superlayer.bounds.width
    let height = superlayer.bounds.height
    
    shapeLayer.frame = superlayer.bounds
    
    let centerX = width / 2
    let centerY = height / 2
    let maxRadius = min(centerX, centerY)
    
    let path = UIBezierPath()
    path.move(to: CGPoint(x: centerX, y: centerY))
    
    for i in 0..<samples.count {
      let amplitude = CGFloat(samples[i]) * 1.25
      let angle = (CGFloat(i) * 2 * .pi / CGFloat(samples.count)) + rotation
      
      let radius = maxRadius * amplitude
      let x = centerX + cos(angle) * radius
      let y = centerY + sin(angle) * radius
      
      path.addLine(to: CGPoint(x: x, y: y))
    }

    path.close()
    var hue = 0.0 as CGFloat
    mainColor.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
    
    let color = UIColor(hue: hue + sin(colorShift) * 20 / 360, saturation: 0.8, brightness: 0.6, alpha: 1).cgColor
    shapeLayer.fillColor = color
    shapeLayer.strokeColor = color
    shapeLayer.lineWidth = 5
    shapeLayer.path = path.cgPath
    
    rotation += 0.002
    colorShift += 0.005
  }
}

