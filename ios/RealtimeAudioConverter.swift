import Foundation
import AVFoundation

class RealtimeAudioConverter: @unchecked Sendable {
    private let inputFormat: AVAudioFormat
    private let outputFormat: AVAudioFormat
    private let audioConverter: AVAudioConverter
    private var bufferQueue: [AVAudioPCMBuffer] = []
    private var currentInputBuffer: AVAudioPCMBuffer?
    private var currentInputBufferSampleOffset: UInt32 = 0

    init?(inputFormat: AVAudioFormat, outputFormat: AVAudioFormat) {
        self.inputFormat = inputFormat
        self.outputFormat = outputFormat
        let converter = AVAudioConverter(from: self.inputFormat, to: self.outputFormat)
        self.audioConverter = converter!
    }
    
    func addBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferQueue.append(buffer)
    }
    
    func isEmpty() -> Bool {
        return bufferQueue.isEmpty
    }
    
    func clear() {
        bufferQueue.removeAll()
    }
    
    func getNextBuffer() -> AVAudioPCMBuffer? {
        if currentInputBuffer == nil {
            if bufferQueue.isEmpty {
                return nil;
            }
            currentInputBuffer = bufferQueue.removeFirst()
            currentInputBufferSampleOffset = 0
        }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: 1200)!
        var error: NSError?
        audioConverter.convert(to: outputBuffer, error: &error) { numSamplesNeeded, inputStatus in
            let numSamplesAvailable = self.currentInputBuffer!.frameLength - self.currentInputBufferSampleOffset
            let samplesToCopy = min(numSamplesAvailable, numSamplesNeeded)
            
            let tempBuffer = AVAudioPCMBuffer(pcmFormat: self.currentInputBuffer!.format,
                                              frameCapacity: numSamplesNeeded)!
            tempBuffer.frameLength = numSamplesNeeded
            
            let bytesPerFrame = self.currentInputBuffer!.format.streamDescription.pointee.mBytesPerFrame
            let sourceOffset = self.currentInputBufferSampleOffset * bytesPerFrame
            let sourceData = self.currentInputBuffer!.audioBufferList.pointee.mBuffers
            let destData = tempBuffer.audioBufferList.pointee.mBuffers
            
            destData.mData?.copyMemory(from: sourceData.mData!.advanced(by: Int(sourceOffset)),
                                       byteCount: Int(samplesToCopy * bytesPerFrame))
            
            self.currentInputBufferSampleOffset += samplesToCopy
            
            if samplesToCopy < numSamplesNeeded {
                self.currentInputBufferSampleOffset = 0
                if self.bufferQueue.isEmpty {
                    self.currentInputBuffer = nil
                    inputStatus.pointee = .endOfStream
                    tempBuffer.frameLength = samplesToCopy
                    return tempBuffer
                }
                self.currentInputBuffer = self.bufferQueue.removeFirst()
                
                let samplesRemaining = numSamplesNeeded - samplesToCopy
                let sourceData = self.currentInputBuffer!.audioBufferList.pointee.mBuffers
                destData.mData?.advanced(by: Int(samplesToCopy * bytesPerFrame)).copyMemory(from: sourceData.mData!,
                                                                                            byteCount: Int(samplesRemaining * bytesPerFrame))
                self.currentInputBufferSampleOffset += samplesRemaining
            }
            inputStatus.pointee = .haveData
            return tempBuffer
        }

        return outputBuffer
    }
}
