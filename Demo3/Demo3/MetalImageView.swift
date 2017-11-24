//
//  MetalImageView.swift
//  Demo3
//
//  Created by Jay Lyerly on 11/24/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import MetalKit

/// `MetalImageView` extends an `MTKView` and exposes an `image` property of type `CIImage` to
/// simplify Metal based rendering of Core Image filters.
class MetalImageView: MTKView {
    private let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    lazy private var commandQueue: MTLCommandQueue? = {
        [unowned self] in
        
        return self.device?.makeCommandQueue()
        }()
    
    lazy private var ciContext: CIContext? = {
        [unowned self] in
        if let device = self.device {
            return CIContext(mtlDevice: device)
        } else {
            return nil
        }
        }()
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect,
                   device: device ?? MTLCreateSystemDefaultDevice())
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        device = MTLCreateSystemDefaultDevice()
        commonInit()
    }
    
    fileprivate func commonInit() {
        if super.device == nil {
            fatalError("Device doesn't support Metal")
        }
        
        framebufferOnly = false
        isPaused = true
        enableSetNeedsDisplay = true
    }
    
    /// The image to display
    var image: CIImage? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    override func draw(_ rect: CGRect) {
        guard window != nil else {      // Don't try to render if the window has been closed.
            return
        }
        guard let image = image,
            let targetTexture = currentDrawable?.texture,
            let commandBuffer = commandQueue?.makeCommandBuffer() else {
                return
        }
        clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        let bounds = CGRect(origin: CGPoint.zero, size: drawableSize)
        
        // black out the whole bounds first
        ciContext?.render(CIImage(color: CIColor(red: 0, green: 0, blue: 0, alpha: 1)),
                          to: targetTexture,
                          commandBuffer: commandBuffer,
                          bounds: bounds,
                          colorSpace: colorSpace)
        
        let originX = image.extent.origin.x
        let originY = image.extent.origin.y
        
        let scaleX = drawableSize.width / image.extent.width
        let scaleY = drawableSize.height / image.extent.height
        let scale = min(scaleX, scaleY)
        
        let delX, delY: CGFloat
        if scale == scaleX {
            delY = 0.5 * (drawableSize.height - (image.extent.height * scale))
            delX = 0
        } else {
            delX = 0.5 * (drawableSize.width - (image.extent.width * scale))
            delY = 0
        }
        let scaledImage = image
            .applying(CGAffineTransform(translationX: -originX, y: -originY))
            .applying(CGAffineTransform(scaleX: scale, y: scale))
            .applying(CGAffineTransform(translationX: delX, y: delY))
        
        ciContext?.render(scaledImage,
                          to: targetTexture,
                          commandBuffer: commandBuffer,
                          bounds: bounds,
                          colorSpace: colorSpace)
        
        if let currentDrawable = currentDrawable {
            commandBuffer.present(currentDrawable)
        }
        
        commandBuffer.commit()
    }
}
