//
//  AppDelegate.swift
//  Demo2
//
//  Created by Jay Lyerly on 11/24/17.
//

import AVFoundation
import AVKit
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        
        let window = NSApp.windows.first
        let viewController = window?.contentViewController as? ViewController
        viewController?.playerController.videoUrl = url
        
        return true
    }
}
