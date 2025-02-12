import UIKit
import AVFoundation

class TripleCircleVisualizer: BaseVisualizer {
  private var rotation: CGFloat = 0
  private var colorShift: CGFloat = 0
  private var hue: CGFloat = 210
  
  override func clearVisualization() {
    super.clearVisualization()
    shapeLayer.contents = nil
  }
  
  override func updateVisualization(with samples: [Float]) {
    let width = shapeLayer.bounds.width
    let height = shapeLayer.bounds.height
    
    UIGraphicsBeginImageContext(shapeLayer.bounds.size)
    guard let context = UIGraphicsGetCurrentContext() else {
      UIGraphicsEndImageContext()
      return
    }
    
    let centerX = width / 2
    let centerY = height / 2
    let maxRadius = min(centerX, centerY) - 10
    
    // Draw outer circle
    context.beginPath()
    let outerStrokeColor = UIColor(hue: hue/360 + sin(colorShift) * 20/360, saturation: 0.8, brightness: 0.6, alpha: 1).cgColor
    context.setStrokeColor(outerStrokeColor)
    context.setLineWidth(2)
    context.addArc(center: CGPoint(x: centerX, y: centerY), radius: maxRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    context.strokePath()
    
    // Define base colors with shifting hues
    let baseHue = CGFloat(hue + sin(colorShift) * 20)
    let waveforms: [(baseRadius: CGFloat, color: UIColor, gradientColors: [UIColor], rotation: CGFloat)] = [
      (baseRadius: maxRadius * 0.8, color: UIColor(hue: baseHue/360, saturation: 0.9, brightness: 0.7, alpha: 1), gradientColors: [UIColor(hue: baseHue/360, saturation: 0.9, brightness: 0.7, alpha: 0.3), UIColor(hue: baseHue/360, saturation: 0.9, brightness: 0.5, alpha: 0)], rotation: rotation),
      (baseRadius: maxRadius * 0.6, color: UIColor(hue: (baseHue + 10)/360, saturation: 0.85, brightness: 0.6, alpha: 1), gradientColors: [UIColor(hue: (baseHue + 10)/360, saturation: 0.85, brightness: 0.6, alpha: 0.3), UIColor(hue: (baseHue + 10)/360, saturation: 0.85, brightness: 0.4, alpha: 0)], rotation: rotation + (.pi * 2 / 3)),
      (baseRadius: maxRadius * 0.4, color: UIColor(hue: (baseHue + 20)/360, saturation: 0.8, brightness: 0.5, alpha: 1), gradientColors: [UIColor(hue: (baseHue + 20)/360, saturation: 0.8, brightness: 0.5, alpha: 0.3), UIColor(hue: (baseHue + 20)/360, saturation: 0.8, brightness: 0.3, alpha: 0)], rotation: rotation + (.pi * 4 / 3))
    ]
    
    waveforms.forEach { waveform in
      var points: [CGPoint] = []
      for i in 0..<samples.count {
        // Assuming samples are in the range [-1, 1]
        let amplitude = (samples[i] + 1) / 2 // Scaling to [0, 1]
        let angle = (CGFloat(i) * 2 * .pi / CGFloat(samples.count)) + waveform.rotation
        
        let radius = waveform.baseRadius + (maxRadius * 0.4 * CGFloat(amplitude))
        let x = centerX + cos(angle) * radius
        let y = centerY + sin(angle) * radius
        
        points.append(CGPoint(x: x, y: y))
      }
      
      // Create gradient for fill
      let gradientColors = [waveform.gradientColors[0].cgColor, waveform.gradientColors[1].cgColor] as CFArray
      let gradientLocations: [CGFloat] = [0.0, 1.0]
      guard let gradient = CGGradient(colorsSpace: nil, colors: gradientColors, locations: gradientLocations) else { return }
      
      context.saveGState()
      context.beginPath()
      context.move(to: CGPoint(x: centerX, y: centerY))
      for point in points {
        context.addLine(to: point)
      }
      context.closePath()
      context.clip()
      
      context.drawRadialGradient(gradient, startCenter: CGPoint(x: centerX, y: centerY), startRadius: waveform.baseRadius * 0.8, endCenter: CGPoint(x: centerX, y: centerY), endRadius: waveform.baseRadius * 1.2, options: [])
      context.restoreGState()
      
      context.beginPath()
      if let firstPoint = points.first {
          context.move(to: firstPoint)
          for point in points.dropFirst() {
              context.addLine(to: point)
          }
      }
      context.setStrokeColor(waveform.color.cgColor)
      context.setLineWidth(4)
      context.closePath()
      context.strokePath()
      
      context.setShadow(offset: .zero, blur: 15, color: waveform.color.cgColor)
    }
    
    rotation += 0.002
    colorShift += 0.005
    
    if let cgImage = context.makeImage() {
      shapeLayer.contents = cgImage
    }
    UIGraphicsEndImageContext()
  }
  
  override func setColor(_ color: UIColor) {
    super.setColor(color)
    color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
  }
}
