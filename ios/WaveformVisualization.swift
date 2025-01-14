import AVFoundation

class WaveformVisualization: AudioVisualization {
    private let waveformLayer = CAShapeLayer()
    private var sampleCount: Int
    
    var layer: CALayer {
        return waveformLayer
    }
    
    init(sampleCount: Int = 100) {
        self.sampleCount = sampleCount
        setupWaveformLayer()
    }
    
    private func setupWaveformLayer() {
        waveformLayer.strokeColor = UIColor.blue.cgColor
        waveformLayer.fillColor = nil
        waveformLayer.lineWidth = 2.0
    }
    
    func getSamplesFromAudio(_ buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData else {
            print("Error: Could not access float channel data")
            return []
        }
        
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        let strideLength = max(1, frameLength / sampleCount)
        
        var samples: [Float] = []
        
        for i in stride(from: 0, to: frameLength, by: strideLength) {
            var sample: Float = 0
            for channel in 0..<channelCount {
                sample += abs(channelData[channel][i])
            }
            sample /= Float(channelCount)
            samples.append(sample)
        }
        
        // Adjust sample count if necessary
        while samples.count > sampleCount {
            samples.removeLast()
        }
        while samples.count < sampleCount {
            samples.append(0)
        }

        return samples
    }

    
    func updateVisualization(with samples: [Float]) {
        let path = UIBezierPath()
        let width = waveformLayer.bounds.width
        let height = waveformLayer.bounds.height
        let midPoint = height / 2
        let sampleWidth = width / CGFloat(samples.count)
        
        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * sampleWidth
            let sampleHeight = CGFloat(sample) * height
            
            path.move(to: CGPoint(x: x, y: midPoint - sampleHeight/2))
            path.addLine(to: CGPoint(x: x, y: midPoint + sampleHeight/2))
        }
        waveformLayer.path = path.cgPath
    }
    
    func setColor(_ color: UIColor) {
        waveformLayer.strokeColor = color.cgColor
    }
    
    func setFrame(_ frame: CGRect) {
        waveformLayer.frame = frame
    }
}
