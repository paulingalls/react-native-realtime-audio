import Foundation
import AVFoundation

class RealtimeAudioConverter: @unchecked Sendable {
  private let inputFormat: AVAudioFormat
  private let outputFormat: AVAudioFormat
  private let audioConverter: AVAudioConverter
  private var bufferQueue: [AVAudioPCMBuffer] = []
  private var currentInputBuffer: AVAudioPCMBuffer?
  private var currentInputBufferSampleOffset: UInt32 = 0
  private var frameSize: UInt32
  private let semaphore = DispatchSemaphore(value: 0)
  private let inputBufferLock = NSLock()
  
  
  init?(inputFormat: AVAudioFormat, outputFormat: AVAudioFormat, frameSize: UInt32) {
    self.outputFormat = outputFormat
    self.inputFormat = inputFormat
    self.frameSize = frameSize
    self.audioConverter = AVAudioConverter(from: inputFormat, to: outputFormat)!
  }
  
  func addBuffer(_ buffer: AVAudioPCMBuffer) {
    bufferQueue.append(buffer)
    print("bufferQueue count: \(bufferQueue.count)")
    semaphore.signal()
  }
  
  func getDepth() -> Int {
    return bufferQueue.count
  }
  
  func isReady() -> Bool {
    if bufferQueue.isEmpty {
      return false
    }
    var bufferDuration: Float32 = 0.0
    for buffer in bufferQueue {
      bufferDuration += Float32(buffer.frameLength) / Float32(inputFormat.sampleRate)
    }
    return bufferDuration > 1.0
  }
  
  func clear() {
    inputBufferLock.lock()
    bufferQueue.removeAll()
    audioConverter.reset()
    currentInputBuffer = nil
    currentInputBufferSampleOffset = 0
    inputBufferLock.unlock()
  }
  
  func getNextBuffer() -> AVAudioPCMBuffer? {
    inputBufferLock.lock()
    if currentInputBuffer == nil {
      let result = semaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.milliseconds(1))
      if bufferQueue.isEmpty || result == .timedOut {
        inputBufferLock.unlock()
        print("getNextBuffer cleared lock with empty queue")
        return nil;
      }
      currentInputBuffer = bufferQueue.removeFirst()
      currentInputBufferSampleOffset = 0
    }
    
    let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameSize)!
    var error: NSError?
    let status = audioConverter.convert(to: outputBuffer, error: &error) { numSamplesNeeded, inputStatus in
      if self.currentInputBuffer == nil {
        inputStatus.pointee = .endOfStream
        return nil
      }
      var numSamplesAvailable: UInt32 = 0
      if self.currentInputBuffer!.frameLength > self.currentInputBufferSampleOffset {
        numSamplesAvailable = self.currentInputBuffer!.frameLength - self.currentInputBufferSampleOffset
      } else {
        print("not enough bits in this buffer")
      }
      var samplesToCopy = min(numSamplesAvailable, numSamplesNeeded)
      
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
        repeat {
          self.currentInputBufferSampleOffset = 0
          let result = self.semaphore.wait(timeout: DispatchTime.now() + DispatchTimeInterval.milliseconds(1))
          if self.bufferQueue.isEmpty {
            print("buffer empty, sending endOfStream, result: \(result)")
            self.currentInputBuffer = nil
            inputStatus.pointee = .endOfStream
            tempBuffer.frameLength = samplesToCopy
            return tempBuffer
          }
          self.currentInputBuffer = self.bufferQueue.removeFirst()
          print("removed buffer from queue (size: \(self.bufferQueue.count))")
          
          let samplesDesired = numSamplesNeeded - samplesToCopy
          let samplesRemaining = self.currentInputBuffer!.frameLength
          let samplesLeftToCopy = min(samplesRemaining, samplesDesired)
          
          let sourceData = self.currentInputBuffer!.audioBufferList.pointee.mBuffers
          destData.mData?.advanced(by: Int(samplesToCopy * bytesPerFrame)).copyMemory(from: sourceData.mData!,
                                                                                      byteCount: Int(samplesLeftToCopy * bytesPerFrame))
          self.currentInputBufferSampleOffset += samplesLeftToCopy
          samplesToCopy += samplesLeftToCopy
        } while samplesToCopy < numSamplesNeeded
      }
      inputStatus.pointee = .haveData
      return tempBuffer
    }
    
    inputBufferLock.unlock()
    if status == AVAudioConverterOutputStatus.endOfStream {
      print("end of stream")
      return nil
    }
    return outputBuffer
  }
}
