//
//  PlayerController.swift
//  Demo2
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

class PlayerController: NSObject {
    
    weak var delegate: PlayerControllerDelegate?
    
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
            let item = AVPlayerItem(url: videoUrl)
            player.replaceCurrentItem(with: item)
            player.play()
            delegate?.playerController(self, didChangeUrl: videoUrl)
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

