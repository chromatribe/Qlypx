//
//  NSImage+Resize.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2015/07/26.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation
import Cocoa

extension NSImage {
    func resizeImage(_ width: CGFloat, _ height: CGFloat) -> NSImage? {
        let targetSize = NSSize(width: width, height: height)
        let imageSize = self.size
        
        if imageSize.width == 0 || imageSize.height == 0 { return nil }
        
        let widthRatio  = targetSize.width  / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        
        // Keep aspect ratio
        let ratio = min(widthRatio, heightRatio)
        let newSize = NSSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        
        // Don't upscale
        if imageSize.width <= newSize.width && imageSize.height <= newSize.height {
            return self
        }

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: imageSize),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        
        return newImage
    }
}
