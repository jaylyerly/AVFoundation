//
//  PlayerController.swift
//  Demo3
//
//  Created by Jay Lyerly on 11/24/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import AVFoundation
import Foundation

protocol PlayerControllerDelegate: class {
    func playerController(_ playerController: PlayerController, didChangeRate rate: Float)
    func playerController(_ playerController: PlayerController, didChangeUrl url: URL?)
    func playerController(_ playerController: PlayerController, didChangePosition position: Float)
}

protocol PlayerControllerImageDelegate: class {
    func playerController(_ playerController: PlayerController, hasNewImage image: CIImage)
}

private let pixelBufferDict: [String: Any] =
    [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]

class PlayerController: NSObject {
    
    weak var delegate: PlayerControllerDelegate?
    weak var imageDelegate: PlayerControllerImageDelegate?
    
    var displayLink: CVDisplayLink?
    var videoOutput: AVPlayerItemVideoOutput?

    let player = AVPlayer()
    var timeObserver: Any?
    var isPlaying: Bool {
        return player.rate != 0.0
    }
    var isSeekInProgress = false
    var chaseTime = kCMTimeZero
    
    var videoUrl: URL? {
        didSet {
            guard let videoUrl = videoUrl else {
                delegate?.playerController(self, didChangeUrl: nil)
                return
            }
            if let displayLink = displayLink {
                CVDisplayLinkStop(displayLink)
                self.displayLink = nil
            }
            
            let item = AVPlayerItem(url: videoUrl)
            player.replaceCurrentItem(with: item)
            let vOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: pixelBufferDict)
            player.currentItem?.add(vOutput)
            videoOutput = vOutput
            
            player.play()
            delegate?.playerController(self, didChangeUrl: videoUrl)
            initDisplayLink()
        }
    }
    var duration: CMTime {
        return player.currentItem?.duration ?? kCMTimeZero
    }
    
    override init() {
        super.init()
        
        player.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
        addTimeObserver()
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let somePlayer = object as? AVPlayer, somePlayer == player {
            switch (keyPath ?? "") {
            case "rate":
                delegate?.playerController(self, didChangeRate: player.rate)
            default:
                break
            }
        }
    }
    
    func addTimeObserver() {
        let interval = CMTime(seconds: 0.1,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let mainQueue = DispatchQueue.main
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) {
                [weak self] time in
            if let duration = self?.duration, let strongSelf = self {
                let progress = Float(time.seconds / duration.seconds)
                self?.delegate?.playerController(strongSelf, didChangePosition: progress)
            }
        }
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(toPosition position: Float) {
        let seconds = duration.seconds * Double(position)
        let positionTime = CMTime(seconds: seconds,
                                  preferredTimescale: duration.timescale)
        smoothSeek(to: positionTime)
    }
}

extension PlayerController {
    // This is Apple's suggested code for implementing an AVPlayer scrubber.
    // You have to wait for a seek to finish before issuing a new seek,
    // Otherwise the previous one gets cancelled and you don't get a smooth seek.
    // From https://developer.apple.com/library/content/qa/qa1820/_index.html
    
    fileprivate func smoothSeek(to newChaseTime: CMTime) {
        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime
            
            if !isSeekInProgress {
                actuallySeekToTime()
            }
        }
    }
    
    fileprivate func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        player.seek(to: seekTimeInProgress, toleranceBefore: kCMTimeZero,
                     toleranceAfter: kCMTimeZero) { (isFinished: Bool) -> Void in
                        guard isFinished else {
                            return
                        }
                        
                        if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                            self.isSeekInProgress = false
                        } else {
                            self.actuallySeekToTime()
                        }
        }
    }
}

extension PlayerController {        // DisplayLink stuff

    func initDisplayLink() {
        // from http://stackoverflow.com/a/33216760/436040
        
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink,
            inNow: UnsafePointer<CVTimeStamp>,
            inOutputTime: UnsafePointer<CVTimeStamp>,
            flagsIn: CVOptionFlags,
            flagsOut: UnsafeMutablePointer<CVOptionFlags>,
            displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            
            let pController = unsafeBitCast(displayLinkContext, to: PlayerController.self)
            pController.handleNewSamples()
            
            //  We are going to assume that everything went well, and success as the CVReturn
            return kCVReturnSuccess
        }
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        if let displayLink = displayLink {
            CVDisplayLinkSetOutputCallback(displayLink, displayLinkOutputCallback,
                                           UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
            CVDisplayLinkStart(displayLink)
        } else {
            assertionFailure("Failed to create displaylink")
        }
    }
    
    func handleNewSamples() {
        autoreleasepool {
            guard let videoOutput = videoOutput else {
                return
            }
            
            let time = CACurrentMediaTime()
            let itemTime = videoOutput.itemTime(forHostTime: time)
            if videoOutput.hasNewPixelBuffer(forItemTime: itemTime) {
                // pixelBuffer is a CVPixelBuffer?
                let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: itemTime,
                                                              itemTimeForDisplay: nil)
                
                print("\(itemTime.seconds)")
                if let pBuf = pixelBuffer {
                    let videoImage = CIImage(cvPixelBuffer: pBuf)
                    DispatchQueue.main.async {
                        self.imageDelegate?.playerController(self, hasNewImage: videoImage)
                    }
                }
            }
        }
    }

}
