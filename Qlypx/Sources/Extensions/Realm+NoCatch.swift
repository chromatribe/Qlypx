//
//  Realm+NoCatch.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2016/03/11.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation
import RealmSwift

extension Realm {
    func transaction(_ block: (() throws -> Void)) {
        do {
            try write(block)
        } catch {}
    }
}
