//
//  QLYClip.swift
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

final class QLYClip: Codable {
    var dataPath: String = ""
    var title: String = ""
    var dataHash: String = ""
    var primaryType: String = ""
    var updateTime: Int = 0
    var thumbnailPath: String = ""
    var isColorCode: Bool = false

    var fullDataPath: String {
        if dataPath.isEmpty { return "" }
        if dataPath.hasPrefix("/") { return dataPath }
        return (QLYUtilities.applicationSupportFolder() as NSString).appendingPathComponent(dataPath)
    }

    init(dataPath: String = "", title: String = "", dataHash: String = "", primaryType: String = "", updateTime: Int = 0, thumbnailPath: String = "", isColorCode: Bool = false) {
        self.dataPath = dataPath
        self.title = title
        self.dataHash = dataHash
        self.primaryType = primaryType
        self.updateTime = updateTime
        self.thumbnailPath = thumbnailPath
        self.isColorCode = isColorCode
    }
}
