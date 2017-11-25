//
//  ViewController.swift
//  Demo3
//
//  Created by Jay Lyerly on 11/24/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var metalView: MetalImageView!
    @IBOutlet weak var videoControlsView: NSView!

    @IBOutlet weak var playButton: NSButton!
    @IBOutlet weak var videoSlider: NSSlider!
    @IBOutlet weak var videoLabel: NSTextField!
    
    var rotation: CGFloat = 0.0
    var sepiaIntensity: CGFloat = 0.0
    
    let playerController = PlayerController()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        playerController.delegate = self
        playerController.imageDelegate = self

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

extension ViewController: PlayerControllerImageDelegate {
    func playerController(_ playerController: PlayerController, hasNewImage image: CIImage) {
        metalView.image = image
            .applying(CGAffineTransform(rotationAngle: rotation))
            .applyingFilter("CISepiaTone",
                            withInputParameters: ["inputIntensity": sepiaIntensity])
    }
}
