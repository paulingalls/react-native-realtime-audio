import AVFoundation

class BarGraphVisualizer: BaseVisualizer {

  override func updateVisualization(with samples: [Float]) {
    let width = shapeLayer.bounds.width
    let height = shapeLayer.bounds.height
    let barCount: Int = 20
    let minBarHeight: CGFloat = height * 0.1
    let barWidth: CGFloat = width / CGFloat(barCount)
    let gap: CGFloat = 4.0
    let div: Int = samples.count / barCount

    let path = UIBezierPath()
    for i in 0..<barCount {
        let bytePosition: Int = Int(ceil(Double(i * div)))
        let amplitude: CGFloat = CGFloat(abs(samples[bytePosition]))
        let top: CGFloat = height - minBarHeight - (amplitude * (height - minBarHeight))
        let barX: CGFloat = (CGFloat(i) * barWidth) + (barWidth / 2)
        
        path.move(to: CGPoint(x: barX, y: height))
        path.addLine(to: CGPoint(x: barX, y: top))
    }
    shapeLayer.lineWidth = barWidth - gap
    shapeLayer.strokeColor = mainColor.cgColor
    shapeLayer.path = path.cgPath
  }
}
