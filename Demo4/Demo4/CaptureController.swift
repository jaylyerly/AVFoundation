//
//  CaptureController.swift
//  Demo4
//
//  Created by Jay Lyerly on 11/25/17.
//

import AVFoundation
import CoreMediaIO
import Foundation

protocol CaptureControllerDelegate: class {
    func captureController(_ captureController: CaptureController,
                           didCaptureImage image: CIImage,
                           atTime time: CMTime)
}

class CaptureController: NSObject {
    
    weak var delegate: CaptureControllerDelegate?
    
    var devices: [AVCaptureDevice] {
        let muxDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeMuxed)
            as? [AVCaptureDevice] ?? []
        let vidDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
            as? [AVCaptureDevice] ?? []
        let devices = vidDevices + muxDevices
        // filter unavailable, ie, built in iSight with laptop closed
        return devices.filter { !$0.isSuspended }
    }
    
    var selectedDevice: AVCaptureDevice? {
        willSet {
            stopCapture()
        }
        didSet {
            print("Selected capture device: \(String(describing: selectedDevice))")
            startCapture()
        }
    }
    
    private var session: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var dataOutput: AVCaptureVideoDataOutput?
    private let captureQueue = DispatchQueue(label: "CaptureQueue", qos: .userInteractive)

    private var cameraConnectObserver: NSObjectProtocol?
    private var cameraDisconnectObserver: NSObjectProtocol?
    
    override init() {
        super.init()
        enableIosDevices()
        validateSelectedDevice()
        
        let devHandler: ((Notification) -> Void) = { _ in
            self.validateSelectedDevice()
        }
        
        let defCenter = NotificationCenter.default
        let connectNotification = Notification.Name.AVCaptureDeviceWasConnected
        cameraConnectObserver = defCenter
            .addObserver(forName: connectNotification,
                         object: nil,
                         queue: nil,
                         using: devHandler)
        let disconnectNotification = Notification.Name.AVCaptureDeviceWasDisconnected
        cameraDisconnectObserver = defCenter
            .addObserver(forName: disconnectNotification,
                         object: nil,
                         queue: nil,
                         using: devHandler)
    }

    func validateSelectedDevice() {
        // if nothing is selected, pick the first devices
        guard let selectedDevice = selectedDevice else {
            self.selectedDevice = devices.first
            return
        }
        
        let deviceAvailable = devices.contains { (camera) -> Bool in
            return camera.uniqueID == selectedDevice.uniqueID
        }
        if !deviceAvailable {
            self.selectedDevice = devices.first
        }
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
    
    private func prepForCapture() {
        dataOutput = AVCaptureVideoDataOutput()
        session = AVCaptureSession()
        
        guard let dataOutput = dataOutput, let session = session else {
            assertionFailure("Failed precondition in prepForCapture")
            return
        }
        
        dataOutput.alwaysDiscardsLateVideoFrames = true
        dataOutput.setSampleBufferDelegate(self, queue: captureQueue)
        
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
        } else {
            print("Can't add dataOutput to session")
        }
        
        session.beginConfiguration()
        
        if let videoDeviceInput = videoDeviceInput {
            session.removeInput(videoDeviceInput)
        }
        
        videoDeviceInput = try? AVCaptureDeviceInput(device: selectedDevice)
        
        guard let videoDeviceInput = videoDeviceInput else {
            assertionFailure("Failed create videoDeviceInput")
            return
        }
        
        session.sessionPreset = AVCaptureSessionPresetHigh
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        }
        
        session.commitConfiguration()
    }
    
    func startCapture() {
        prepForCapture()
        session?.startRunning()
    }
    
    func stopCapture() {
        session?.stopRunning()
    }
}

extension CaptureController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ captureOutput: AVCaptureOutput?,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer?,
                       from connection: AVCaptureConnection?) {
        
        autoreleasepool {
            if let sampleBuffer = sampleBuffer,
                let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
                
                let syncTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let image = CIImage(cvPixelBuffer: imageBuffer)
                DispatchQueue.main.async {
                    self.delegate?.captureController(self, didCaptureImage: image, atTime: syncTime)
                }
                CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput?,
                       didDrop sampleBuffer: CMSampleBuffer?,
                       from connection: AVCaptureConnection?) {
        print("Failed to capture output.")
    }
}
