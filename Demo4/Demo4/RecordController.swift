//
//  RecordController.swift
//  Demo4
//
//  Created by Jay Lyerly on 11/25/17.
//

import AVFoundation
import Foundation

class RecordController: NSObject {
    
    var size: NSSize = NSSize(width: 100, height: 100)
    
    let recordingQueue = DispatchQueue(label: "RecordingQueue",
                                       qos: .userInteractive)
    private let ciContext = CIContext(options: nil)

    var recording: Bool = false
    var h264Recorder: AVAssetWriter?
    var inputAdapter: AVAssetWriterInputPixelBufferAdaptor?
    var videoRecorderInput: AVAssetWriterInput?
    
    var hasSetRecordSessionStartTime = false
    var lastFrameTime = kCMTimeZero

    func record() {
        recordingQueue.async {
            self.queueRecord()
        }
    }
    
    private func queueRecord() {
        guard !recording else {
            return      // don't double record
        }
        
        recording = true
        
        let captureUrl = FileManager.default.recordMovieUrl
        
        let newAssetWriter: AVAssetWriter
        do {
            newAssetWriter = try AVAssetWriter(url: captureUrl, fileType: AVFileTypeQuickTimeMovie)
        } catch {
            assertionFailure("Failed to create AVAssetWriter")
            h264Recorder = nil
            return
        }
        
        addVideoInput(assetWriter: newAssetWriter)
        
        if !newAssetWriter.startWriting() || newAssetWriter.status == .failed {
            assertionFailure("Failed to start recording")
        }
        
        h264Recorder = newAssetWriter
    }
    
    func addVideoInput(assetWriter: AVAssetWriter) {
        let width = size.width
        let height = size.height
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoMaxKeyFrameIntervalKey: 1,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
            
        ]
        
        let vRecInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo,
                                           outputSettings: videoSettings)
        vRecInput.expectsMediaDataInRealTime = true
        
        let pixBufAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height
        ]
        inputAdapter = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: vRecInput,
            sourcePixelBufferAttributes: pixBufAttrs
        )
        
        if assetWriter.canAdd(vRecInput) {
            assetWriter.add(vRecInput)
        }
        
        videoRecorderInput = vRecInput
    }

    func stop() {
        recordingQueue.async {
            self.queueStop()
        }
    }
    
    private func queueStop() {
        guard recording, let h264Recorder = h264Recorder else {
            return      // don't double stop
        }
        
        recording = false
        
        h264Recorder.endSession(atSourceTime: lastFrameTime)
        
        h264Recorder.finishWriting {
            if let error = h264Recorder.error {
                print("Error closing moving file: \(h264Recorder.status): \(error)")
            }
            
            self.inputAdapter = nil
            self.videoRecorderInput = nil
            self.h264Recorder = nil
            self.hasSetRecordSessionStartTime = false
            self.lastFrameTime = kCMTimeZero
            
            self.recording = false
        }
    }
    
    func recordFrame(_ image: CIImage, syncTime time: CMTime) {
        recordingQueue.async {
            self.recordFrameQueue(image, syncTime: time)
        }
    }

    private func recordFrameQueue(_ image: CIImage, syncTime time: CMTime) {
        // records the current frame available in the overlayRenderer
        guard h264Recorder != nil, recording else {
            return
        }
        
        if !hasSetRecordSessionStartTime {
            h264Recorder?.startSession(atSourceTime: time)
            hasSetRecordSessionStartTime = true
        }
        
        if let videoRecorderInput = videoRecorderInput, recording {
            if videoRecorderInput.isReadyForMoreMediaData {
                if let pixBuf = pixelBuffer(forImage: image) {
                    let didAppend = inputAdapter?.append(pixBuf, withPresentationTime: time) ?? false
                    if !didAppend {
                        assertionFailure("Failed to append video frame to AVAssetWriterInputPixelBufferAdaptor")
                    }
                    lastFrameTime = time
                }
            }
        }

    }
    
    private func pixelBuffer(forImage image: CIImage) -> CVPixelBuffer? {
        guard let pixBufPool = inputAdapter?.pixelBufferPool else {
            assertionFailure("input adapter's pixel buffer pool is nil")
            return nil
        }

        var newPixelBuffer: CVPixelBuffer? = nil
        
        let retval = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixBufPool, &newPixelBuffer)
        if retval != kCVReturnSuccess {
            assertionFailure("Failed to create pixel buffer from pool")
        }
        
        guard let pixBuff = newPixelBuffer else {
            return nil
        }
        
        ciContext.render(image, to: pixBuff, bounds: image.extent, colorSpace: nil)
        
        return newPixelBuffer
    }
}
