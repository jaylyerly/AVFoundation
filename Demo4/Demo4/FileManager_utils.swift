//
//  FileManager_utils.swift
//  Demo4
//
//  Created by Jay Lyerly on 11/25/17.
//  Copyright © 2017 Oak City Labs. All rights reserved.
//

import Foundation

extension FileManager {
    
    private var desktopUrl: URL {
        let paths = urls(for: .desktopDirectory, in: .userDomainMask)
        if let documentsDirectory = paths.first {
            return documentsDirectory
        } else {
            let path = NSString(string: "~/Desktop").expandingTildeInPath
            let url = URL(fileURLWithPath: path)
            return url
        }
    }
    
    var recordMovieUrl: URL {
        let movieName = "demo4-\(Date()).mov"
        return URL(fileURLWithPath: movieName, relativeTo: desktopUrl)
    }
    
}
