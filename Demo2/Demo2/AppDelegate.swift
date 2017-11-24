//
//  AppDelegate.swift
//  Demo1
//
//  Created by Jay Lyerly on 11/24/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import AVKit
import AVFoundation
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

