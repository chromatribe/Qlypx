//
//  QLYClipData.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2015/06/21.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa

final class QLYClipData: NSObject, NSCoding {

    // MARK: - Properties
    fileprivate let kTypesKey       = "types"
    fileprivate let kStringValueKey = "stringValue"
    fileprivate let kRTFDataKey     = "RTFData"
    fileprivate let kPDFKey         = "PDF"
    fileprivate let kFileNamesKey   = "filenames"
    fileprivate let kFileURLsKey    = "fileURLs"
    fileprivate let kURLsKey        = "URL"
    fileprivate let kImageKey       = "image"

    var types          = [NSPasteboard.PasteboardType]()
    var fileNames      = [String]()
    var fileURLs       = [URL]()
    var URLs           = [String]()
    var stringValue    = ""
    var RTFData: Data?
    var PDF: Data?
    var image: NSImage?

    override var hash: Int {
        var hasher = Hasher()
        types.forEach { hasher.combine($0.rawValue) }
        if let image = self.image, let imageData = image.tiffRepresentation {
            hasher.combine(imageData.count)
        } else if let image = self.image {
            hasher.combine(image.hash)
        }
        if !fileURLs.isEmpty {
            fileURLs.forEach { hasher.combine($0) }
        } else if !fileNames.isEmpty {
            fileNames.forEach { hasher.combine($0) }
        } else if !self.URLs.isEmpty {
            URLs.forEach { hasher.combine($0) }
        } else if let pdf = PDF {
            hasher.combine(pdf.count)
        } else if !stringValue.isEmpty {
            hasher.combine(stringValue)
        }
        if let data = RTFData {
            hasher.combine(data.count)
        }
        return hasher.finalize()
    }
    var primaryType: NSPasteboard.PasteboardType? {
        return types.first
    }
    var isOnlyStringType: Bool {
        return types == [.string] || types == [NSPasteboard.PasteboardType.legacyString]
    }
    var thumbnailImage: NSImage? {
        let defaults = UserDefaults.standard
        let width = defaults.integer(forKey: Constants.UserDefaults.thumbnailWidth)
        let height = defaults.integer(forKey: Constants.UserDefaults.thumbnailHeight)

        if let image = image, fileURLs.isEmpty && fileNames.isEmpty {
            // Image only data
            return image.resizeImage(CGFloat(width), CGFloat(height))
        } else if let fileURL = fileURLs.first {
             // Handle via URL
             return NSImage(contentsOf: fileURL)?.resizeImage(CGFloat(width), CGFloat(height))
        } else if let fileName = fileNames.first, let path = fileName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: path) {
             // In the case of the local file correct data is not included in the image variable
             // Judge the image from the path and create a thumbnail
            switch url.pathExtension.lowercased() {
            case "jpg", "jpeg", "png", "bmp", "tiff":
                return NSImage(contentsOfFile: fileName)?.resizeImage(CGFloat(width), CGFloat(height))
            default: break
            }
        }
        return nil
    }
    var colorCodeImage: NSImage? {
        guard let color = NSColor(hexString: stringValue) else { return nil }
        return NSImage.create(with: color, size: NSSize(width: 20, height: 20))
    }

    static var availableTypes: [NSPasteboard.PasteboardType] {
        return [NSPasteboard.PasteboardType.string,
                NSPasteboard.PasteboardType.rtf,
                NSPasteboard.PasteboardType.rtfd,
                NSPasteboard.PasteboardType.pdf,
                NSPasteboard.PasteboardType.fileURL,
                NSPasteboard.PasteboardType.legacyFilenames,
                NSPasteboard.PasteboardType.URL,
                NSPasteboard.PasteboardType.tiff,
                NSPasteboard.PasteboardType.png,
                NSPasteboard.PasteboardType.jpeg,
                NSPasteboard.PasteboardType.gif]
    }
    static var availableTypesString: [String] {
        return ["String",
                "RTF",
                "RTFD",
                "PDF",
                "Filenames",
                "Filenames",
                "URL",
                "TIFF",
                "TIFF",
                "TIFF",
                "TIFF"]
    }
    static var availableTypesDictinary: [NSPasteboard.PasteboardType: String] {
        var availableTypes = [NSPasteboard.PasteboardType: String]()
        zip(QLYClipData.availableTypes, QLYClipData.availableTypesString).forEach { availableTypes[$0] = $1 }
        
        // Legacy mappings
        availableTypes[.legacyString] = "String"
        availableTypes[.legacyRTF] = "RTF"
        availableTypes[.legacyRTFD] = "RTFD"
        availableTypes[.legacyPDF] = "PDF"
        availableTypes[.legacyFilenames] = "Filenames"
        availableTypes[.legacyURL] = "URL"
        availableTypes[.legacyTIFF] = "TIFF"
        
        return availableTypes
    }

    // MARK: - Init
    init(pasteboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) {
        super.init()
        self.types = types
        types.forEach { type in
            switch type {
            case NSPasteboard.PasteboardType.string, NSPasteboard.PasteboardType.legacyString:
                if stringValue.isEmpty, let string = pasteboard.string(forType: type) {
                    stringValue = string
                }
            case NSPasteboard.PasteboardType.rtfd, NSPasteboard.PasteboardType.legacyRTFD:
                if RTFData == nil {
                    RTFData = pasteboard.data(forType: type)
                }
            case NSPasteboard.PasteboardType.rtf, NSPasteboard.PasteboardType.legacyRTF:
                if RTFData == nil {
                    RTFData = pasteboard.data(forType: type)
                }
            case NSPasteboard.PasteboardType.pdf, NSPasteboard.PasteboardType.legacyPDF:
                if PDF == nil {
                    PDF = pasteboard.data(forType: type)
                }
            case NSPasteboard.PasteboardType.fileURL:
                if fileURLs.isEmpty {
                    self.fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] ?? []
                    // Also populate filenames for backward compatibility
                    self.fileNames = fileURLs.map { $0.path }
                }
            case NSPasteboard.PasteboardType.legacyFilenames:
                if fileNames.isEmpty, let filenames = pasteboard.propertyList(forType: NSPasteboard.PasteboardType.legacyFilenames) as? [String] {
                    self.fileNames = filenames
                }
            case NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.legacyURL:
                if URLs.isEmpty, let urls = pasteboard.propertyList(forType: type) as? [String] {
                    URLs = urls
                }
            case _ where type.isImage:
                if image == nil {
                    image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage
                }
            default: break
            }
        }
    }

    init(image: NSImage) {
        self.types = [.tiff, .png, NSPasteboard.PasteboardType.jpeg, NSPasteboard.PasteboardType.gif]
        self.image = image
    }

    deinit {
        self.RTFData = nil
        self.PDF = nil
        self.image = nil
    }

    // MARK: - NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(types.map { $0.rawValue }, forKey: kTypesKey)
        aCoder.encode(stringValue, forKey: kStringValueKey)
        aCoder.encode(RTFData, forKey: kRTFDataKey)
        aCoder.encode(PDF, forKey: kPDFKey)
        aCoder.encode(fileNames, forKey: kFileNamesKey)
        aCoder.encode(fileURLs, forKey: kFileURLsKey)
        aCoder.encode(URLs, forKey: kURLsKey)
        aCoder.encode(image, forKey: kImageKey)
    }

    required init?(coder aDecoder: NSCoder) {
        types = (aDecoder.decodeObject(forKey: kTypesKey) as? [String])?.compactMap { NSPasteboard.PasteboardType(rawValue: $0) } ?? []
        fileNames = aDecoder.decodeObject(forKey: kFileNamesKey) as? [String] ?? [String]()
        fileURLs = aDecoder.decodeObject(forKey: kFileURLsKey) as? [URL] ?? [URL]()
        URLs = aDecoder.decodeObject(forKey: kURLsKey) as? [String] ?? [String]()
        stringValue = aDecoder.decodeObject(forKey: kStringValueKey) as? String ?? ""
        RTFData = aDecoder.decodeObject(forKey: kRTFDataKey) as? Data
        PDF = aDecoder.decodeObject(forKey: kPDFKey) as? Data
        image = aDecoder.decodeObject(forKey: kImageKey) as? NSImage
        super.init()
    }
}
