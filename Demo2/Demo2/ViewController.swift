//
//  ViewController.swift
//  Demo1
//
//  Created by Jay Lyerly on 11/24/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import AVKit
import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var avPlayerView: AVPlayerView!
    @IBOutlet weak var videoControlsView: NSView!

    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var videoSlider: NSSlider!
    @IBOutlet weak var videoLabel: NSTextField!
    
    let playerController = PlayerController()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        playerController.delegate = self
        avPlayerView.contentOverlayView?.addSubViewEdgeToEdge(videoControlsView)
        avPlayerView.player = playerController.player

        videoLabel.stringValue = "Ready for video..."
    }
    
    @IBAction func handleSlider(_ sender: Any) {
        playerController.seek(toPosition: videoSlider.floatValue)
    }

    @IBAction func handlePlayButton(_ sender: Any) {
        playerController.togglePlayPause()
    }
}

extension ViewController: PlayerControllerDelegate {
    func playerController(_ playerController: PlayerController, didChangeRate rate: Float) {
        if rate == 0.0 {
            playButton.title = "Play"
        } else {
            playButton.title = "Pause"
        }
    }
    
    func playerController(_ playerController: PlayerController, didChangeUrl url: URL?) {
        let urlString = url?.absoluteString ?? ""
        videoLabel.stringValue = urlString
    }
    
    func playerController(_ playerController: PlayerController, didChangePosition position: Float) {
        videoSlider.floatValue = position
    }
}
