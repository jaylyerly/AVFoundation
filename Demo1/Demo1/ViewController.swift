//
//  ViewController.swift
//  Demo1
//
//  Created by Jay Lyerly on 11/24/17.
//

import AVFoundation
import AVKit
import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak private var avPlayerView: AVPlayerView!
    
    func play(url: URL) {
        avPlayerView.player = AVPlayer(url: url)
        avPlayerView.player?.play()
    }
}
