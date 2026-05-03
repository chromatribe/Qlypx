//
//  NSMenuItem+Initialize.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2016/03/06.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation
import Cocoa

extension NSMenuItem {
    convenience init(title: String, action: Selector?) {
        self.init(title: title, action: action, keyEquivalent: "")
    }
}
