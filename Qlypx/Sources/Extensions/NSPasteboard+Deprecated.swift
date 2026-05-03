//
//  NSPasteboard+Deprecated.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2017/12/30.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa

extension NSPasteboard.PasteboardType {
    // Legacy support for existing saved items (Raw strings used in Clipy/Older Qlypx)
    static let legacyString    = NSPasteboard.PasteboardType(rawValue: "NSStringPboardType")
    static let legacyRTF       = NSPasteboard.PasteboardType(rawValue: "NSRTFPboardType")
    static let legacyRTFD      = NSPasteboard.PasteboardType(rawValue: "NSRTFDPboardType")
    static let legacyPDF       = NSPasteboard.PasteboardType(rawValue: "NSPDFPboardType")
    static let legacyFilenames = NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")
    static let legacyURL       = NSPasteboard.PasteboardType(rawValue: "NSURLPboardType")
    static let legacyTIFF      = NSPasteboard.PasteboardType(rawValue: "NSTIFFPboardType")
    
    // Modern Image Types (Some are not predefined in older SDKs or for convenience)
    static let jpeg = NSPasteboard.PasteboardType("public.jpeg")
    static let gif  = NSPasteboard.PasteboardType("com.compuserve.gif")
}

extension NSPasteboard.PasteboardType {
    /// Helper to identify if a type is an image
    var isImage: Bool {
        return self == .tiff || self == .png || self == .jpeg || self == .gif || self == .legacyTIFF
    }

    var isPDF: Bool {
        return self == .pdf || self == .legacyPDF
    }

    var isFileURL: Bool {
        return self == .fileURL || self == .legacyFilenames
    }
}
