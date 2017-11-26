//
//  ViewController.swift
//  Demo2
//
//  Created by Jay Lyerly on 11/24/17.
//

import AVKit
import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak fileprivate var avPlayerView: AVPlayerView!
    @IBOutlet weak fileprivate var videoControlsView: NSView!

    @IBOutlet weak fileprivate var playButton: NSButton!
    @IBOutlet weak fileprivate var videoSlider: NSSlider!
    @IBOutlet weak fileprivate var videoLabel: NSTextField!
    
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

        // Bail if the left mouse button is down (ie, slider mid scrub).
        // A bit of a hack, but doesn't require subclassing NSSlider
        guard NSEvent.pressedMouseButtons() != 1 else {
            return
        }
        videoSlider.floatValue = position
    }
}
