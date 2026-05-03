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

final class CPYSnippet: Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var id: String { identifier }
    @Published var index: Int = 0
    @Published var enable: Bool = true
    @Published var title: String = ""
    @Published var content: String = ""
    var identifier: String = UUID().uuidString

    enum CodingKeys: String, CodingKey {
        case index
        case enable
        case title
        case content
        case identifier
    }

    init(index: Int = 0, enable: Bool = true, title: String = "", content: String = "", identifier: String = UUID().uuidString) {
        self.index = index
        self.enable = enable
        self.title = title
        self.content = content
        self.identifier = identifier
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        enable = try container.decode(Bool.self, forKey: .enable)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        identifier = try container.decode(String.self, forKey: .identifier)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(enable, forKey: .enable)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(identifier, forKey: .identifier)
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
