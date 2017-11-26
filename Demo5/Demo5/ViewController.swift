//
//  ViewController.swift
//  Demo5
//
//  Created by Jay Lyerly on 11/26/17.
//

import AVKit
import AVFoundation
import Cocoa
import CoreMediaIO

class ViewController: NSViewController {

    @IBOutlet private weak var captureView: AVCaptureView!

    override func awakeFromNib() {
        super.awakeFromNib()
        enableIosDevices()
        captureView.delegate = self
    }

    private func enableIosDevices() {
        // Opt in to iOS device screen recording
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
        )
        var allow: UInt32 = 1
        let sizeOfAllow = MemoryLayout<UInt32>.size
        CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &property, 0, nil, UInt32(sizeOfAllow), &allow)
    }

}

extension ViewController: AVCaptureViewDelegate {

    func captureView(_ captureView: AVCaptureView,
                     startRecordingTo fileOutput: AVCaptureFileOutput) {
        let url = FileManager.default.recordMovieUrl

        fileOutput.startRecording(toOutputFileURL: url,
                                  recordingDelegate: self)
    }

}

extension ViewController: AVCaptureFileOutputRecordingDelegate {

    func capture(_ captureOutput: AVCaptureFileOutput!,
                 didFinishRecordingToOutputFileAt outputFileURL: URL!,
                 fromConnections connections: [Any]!, error: Error!) {
    }
}
