//
//  CPYSnippet.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2015/06/21.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa

final class CPYSnippet: Codable, Equatable, Hashable {
    var index: Int = 0
    var enable: Bool = true
    var title: String = ""
    var content: String = ""
    var identifier: String = UUID().uuidString

    init(index: Int = 0, enable: Bool = true, title: String = "", content: String = "", identifier: String = UUID().uuidString) {
        self.index = index
        self.enable = enable
        self.title = title
        self.content = content
        self.identifier = identifier
    }

    static func == (lhs: CPYSnippet, rhs: CPYSnippet) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Actions
extension CPYSnippet {
    func merge() {
        // Find folder and update
        for folder in AppEnvironment.current.dataService.folders {
            if let index = folder.snippets.firstIndex(where: { $0.identifier == identifier }) {
                folder.snippets[index] = self
                AppEnvironment.current.dataService.upsertFolder(folder)
                return
            }
        }
    }

    func remove() {
        for folder in AppEnvironment.current.dataService.folders {
            if let index = folder.snippets.firstIndex(where: { $0.identifier == identifier }) {
                folder.snippets.remove(at: index)
                AppEnvironment.current.dataService.upsertFolder(folder)
                return
            }
        }
    }
}
