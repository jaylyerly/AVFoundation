//
//  NSViewUtils.swift
//  Demo3
//
//  Created by Jay Lyerly on 11/24/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import Cocoa

extension NSView {
    func addSubViewEdgeToEdge(_ subview: NSView) {
        self.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[subview]|",
                                                           options: [],
                                                           metrics: nil,
                                                           views: ["subview": subview]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|[subview]|",
                                                           options: [],
                                                           metrics: nil,
                                                           views: ["subview": subview]))
    }
    
}
