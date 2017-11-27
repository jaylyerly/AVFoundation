//
//  AppDelegate.swift
//  Demo3
//
//  Created by Jay Lyerly on 11/24/17.
//

import AVFoundation
import AVKit
import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var viewController: ViewController? {
        let window = NSApp.windows.first
        return window?.contentViewController as? ViewController
    }
    
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        let url = URL(fileURLWithPath: filename)
        play(url: url)
        
        return true
    }
    
    @IBAction func open(_ sender: Any) {
        guard let url = NSOpenPanel().selectUrl else {
            return
        }
        play(url: url)
    }
    
    func play(url: URL) {
        NSDocumentController.shared().noteNewRecentDocumentURL(url)
        viewController?.playerController.videoUrl = url
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
