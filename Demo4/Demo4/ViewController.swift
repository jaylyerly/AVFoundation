//
//  ViewController.swift
//  Demo4
//
//  Created by Jay Lyerly on 11/25/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import AVFoundation
import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var metalView: MetalImageView!
    @IBOutlet weak var controlsView: NSView!
    @IBOutlet weak var devicesController: NSArrayController!

    let captureController = CaptureController()
    let recordController = RecordController()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        view.layer?.backgroundColor = CGColor.black
        controlsView.layer?.backgroundColor = NSColor.lightGray.cgColor
        
        captureController.delegate = self
    }

    @IBAction func toggleRecord(_ sender: NSButton) {
        if sender.state == NSOnState {
            print("Record!")
            record()
        } else {
            print("Stop recording!")
            stop()
        }
    }
    
    @IBAction func handleDeviceSelection(_ sender: NSPopUpButton) {
        if let device = devicesController.selectedObjects.first as? AVCaptureDevice {
            captureController.selectedDevice = device
        }
    }
    
    func record() {
        guard recordController.recording == false else {
            return
        }
        recordController.size = metalView.image?.extent.size ?? NSSize(width: 100, height: 100)
        recordController.record()
    }
    
    func stop() {
        guard recordController.recording == true else {
            return
        }
        recordController.stop()
    }
}

extension ViewController: CaptureControllerDelegate {
    
    func captureController(_ captureController: CaptureController, didCaptureImage image: CIImage, atTime time: CMTime) {
        
        metalView.image = image
        
        if recordController.recording {
            recordController.recordFrame(image, syncTime: time)
        }
        
    }
    
}
