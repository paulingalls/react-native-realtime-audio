import UIKit
import AVFoundation

protocol AudioVisualization: AnyObject {
    var layer: CALayer { get }
    func getSamplesFromAudio(_ audio: AVAudioPCMBuffer) -> [[Float]]
    func updateVisualization(with samples: [Float])
    func setColor(_ color: UIColor)
    func setFrame(_ frame: CGRect)
    func clearVisualization()
}

