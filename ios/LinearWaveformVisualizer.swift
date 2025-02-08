import AVFoundation

class LinearWaveformVisualizer: BaseVisualizer {
  let lineWidth: CGFloat = 2
  
  override func setFrame(_ frame: CGRect) {
    super.setFrame(frame)
    chunkSize = Int(frame.width / lineWidth)
    shapeLayer.fillColor = nil
    shapeLayer.lineWidth = lineWidth
  }

  override func updateVisualization(with samples: [Float]) {
    let path = UIBezierPath()
    let width = shapeLayer.bounds.width
    let height = shapeLayer.bounds.height
    let midPoint = height / 2
    let sampleWidth = width / CGFloat(samples.count)
    
    shapeLayer.strokeColor = mainColor.cgColor
    for (index, sample) in samples.enumerated() {
      let x = CGFloat(index) * sampleWidth
      let sampleHeight = min(CGFloat(sample) * height * 1.5, height)
      
      path.move(to: CGPoint(x: x, y: midPoint - sampleHeight/2))
      path.addLine(to: CGPoint(x: x, y: midPoint + sampleHeight/2))
    }
    shapeLayer.path = path.cgPath
  }
}
