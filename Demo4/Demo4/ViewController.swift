//
//  ViewController.swift
//  Demo4
//
//  Created by Jay Lyerly on 11/25/17.
//

import AVFoundation
import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak fileprivate var metalView: MetalImageView!
    @IBOutlet weak fileprivate var controlsView: NSView!
    @IBOutlet weak fileprivate var filtersView: NSView!
    @IBOutlet weak fileprivate var devicesController: NSArrayController!

    let captureController = CaptureController()
    let recordController = RecordController()
    
    var rotation: CGFloat = 0.0
    var sepiaIntensity: CGFloat = 0.0

    override func awakeFromNib() {
        super.awakeFromNib()
        view.layer?.backgroundColor = CGColor.black
        controlsView.layer?.backgroundColor = NSColor.lightGray.cgColor
        filtersView.layer?.backgroundColor = NSColor.lightGray.cgColor
        
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
    
    func captureController(_ captureController: CaptureController,
                           didCaptureImage image: CIImage,
                           atTime time: CMTime) {
        let newImage = image
            .applyingFilter("CIStraightenFilter",
                            withInputParameters: ["inputAngle": rotation])
            .applyingFilter("CISepiaTone",
                            withInputParameters: ["inputIntensity": sepiaIntensity])

        metalView.image = newImage
        
        if recordController.recording {
            recordController.recordFrame(newImage, syncTime: time)
        }
    }
    
}
