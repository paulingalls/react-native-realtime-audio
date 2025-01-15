import Foundation
import AVFoundation

class RealtimeAudioConverter: @unchecked Sendable {
    private let outputFormat: AVAudioFormat
    private let audioConverter: AVAudioConverter
    private var bufferQueue: [AVAudioPCMBuffer] = []
    private var currentInputBuffer: AVAudioPCMBuffer?
    private var currentInputBufferSampleOffset: UInt32 = 0
    private var frameSize: UInt32
    private let semaphore = DispatchSemaphore(value: 0)


    init?(inputFormat: AVAudioFormat, outputFormat: AVAudioFormat, frameSize: UInt32) {
        self.outputFormat = outputFormat
        self.frameSize = frameSize
        self.audioConverter = AVAudioConverter(from: inputFormat, to: self.outputFormat)!
    }
    
    func addBuffer(_ buffer: AVAudioPCMBuffer) {
        bufferQueue.append(buffer)
        semaphore.signal()
    }
    
    func isEmpty() -> Bool {
        return bufferQueue.isEmpty
    }
    
    func clear() {
        bufferQueue.removeAll()
        audioConverter.reset()
    }
    
    func getNextBuffer() -> AVAudioPCMBuffer? {
        if currentInputBuffer == nil {
            let result = semaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.milliseconds(100))
            if bufferQueue.isEmpty || result == .timedOut {
                return nil;
            }
            currentInputBuffer = bufferQueue.removeFirst()
            currentInputBufferSampleOffset = 0
        }

        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameSize)!
        var error: NSError?
        audioConverter.convert(to: outputBuffer, error: &error) { numSamplesNeeded, inputStatus in
            if self.currentInputBuffer == nil {
                inputStatus.pointee = .endOfStream
                return nil
            }
            var numSamplesAvailable: UInt32 = 0
            if self.currentInputBuffer!.frameLength > self.currentInputBufferSampleOffset {
                numSamplesAvailable = self.currentInputBuffer!.frameLength - self.currentInputBufferSampleOffset
            } else {
                numSamplesAvailable = 0
                self.currentInputBufferSampleOffset = 0
            }
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
                let result = self.semaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.milliseconds(200))
                if self.bufferQueue.isEmpty || result == .timedOut {
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
