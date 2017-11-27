//
//  NSOpenPanel_utils.swift
//  Demo1
//
//  Created by Jay Lyerly on 11/27/17.
//

import Cocoa

extension NSOpenPanel {
    var selectUrl: URL? {
        title = "Select Movie"
        allowedFileTypes = ["public.movie"]
        allowsMultipleSelection = false
        canChooseDirectories = false
        canChooseFiles = true
        canCreateDirectories = false
        runModal()
        return urls.first
    }
}
