import AVFoundation

class WaveformVisualization: AudioVisualization {
    private let waveformLayer = CAShapeLayer()

    var layer: CALayer {
        return waveformLayer
    }
    
    init() {
        setupWaveformLayer()
    }
    
    private func setupWaveformLayer() {
        waveformLayer.strokeColor = UIColor.blue.cgColor
        waveformLayer.fillColor = nil
        waveformLayer.lineWidth = 2.0
    }
    
    func getSamplesFromAudio(_ buffer: AVAudioPCMBuffer) -> [[Float]] {
        guard let channelData = buffer.floatChannelData else {
            print("Error: Could not access float channel data")
            return []
        }

        let sampleCount = Int(waveformLayer.bounds.width / waveformLayer.lineWidth)
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)

        // Calculate how many full pieces we can create
        let pieceCount = frameLength / sampleCount

        var samplePieces: [[Float]] = []

        for pieceIndex in 0..<pieceCount {
            var pieceSamples: [Float] = []

            let startIndex = pieceIndex * sampleCount
            let endIndex = min(startIndex + sampleCount, frameLength)

            for i in startIndex..<endIndex {
                var sample: Float = 0
                for channel in 0..<channelCount {
                    sample += abs(channelData[channel][i])
                }
                sample /= Float(channelCount)
                pieceSamples.append(sample)
            }

            // Adjust sample count if necessary
            while pieceSamples.count > sampleCount {
                pieceSamples.removeLast()
            }
            while pieceSamples.count < sampleCount {
                pieceSamples.append(0)
            }

            samplePieces.append(pieceSamples)
        }

        // Handle any remaining samples
        if frameLength % sampleCount != 0 {
            var remainingSamples: [Float] = []

            let startIndex = pieceCount * sampleCount

            for i in startIndex..<frameLength {
                var sample: Float = 0
                for channel in 0..<channelCount {
                    sample += abs(channelData[channel][i])
                }
                sample /= Float(channelCount)
                remainingSamples.append(sample)
            }

            // Adjust sample count if necessary
            while remainingSamples.count > sampleCount {
                remainingSamples.removeLast()
            }
            while remainingSamples.count < sampleCount {
                remainingSamples.append(0)
            }

            samplePieces.append(remainingSamples)
        }

        return samplePieces
    }
    
    func updateVisualization(with samples: [Float]) {
        let path = UIBezierPath()
        let width = waveformLayer.bounds.width
        let height = waveformLayer.bounds.height
        let midPoint = height / 2
        let sampleWidth = width / CGFloat(samples.count)
        
        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * sampleWidth
            let sampleHeight = min(CGFloat(sample) * height * 1.5, height)
            
            path.move(to: CGPoint(x: x, y: midPoint - sampleHeight/2))
            path.addLine(to: CGPoint(x: x, y: midPoint + sampleHeight/2))
        }
        waveformLayer.path = path.cgPath
    }
    
    func clearVisualization() {
        waveformLayer.path = nil
    }
    
    func setColor(_ color: UIColor) {
        waveformLayer.strokeColor = color.cgColor
    }
    
    func setFrame(_ frame: CGRect) {
        waveformLayer.frame = frame
    }
}
