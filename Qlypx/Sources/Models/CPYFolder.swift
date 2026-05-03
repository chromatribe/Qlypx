//
//  CPYFolder.swift
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

final class CPYFolder: Codable, Equatable, Hashable, Identifiable, ObservableObject {
    var id: String { identifier }
    @Published var index: Int = 0
    @Published var enable: Bool = true
    @Published var title: String = ""
    var identifier: String = UUID().uuidString
    @Published var snippets: [CPYSnippet] = []

    enum CodingKeys: String, CodingKey {
        case index
        case enable
        case title
        case identifier
        case snippets
    }

    init(index: Int = 0, enable: Bool = true, title: String = "", identifier: String = UUID().uuidString, snippets: [CPYSnippet] = []) {
        self.index = index
        self.enable = enable
        self.title = title
        self.identifier = identifier
        self.snippets = snippets
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(Int.self, forKey: .index)
        enable = try container.decode(Bool.self, forKey: .enable)
        title = try container.decode(String.self, forKey: .title)
        identifier = try container.decode(String.self, forKey: .identifier)
        snippets = try container.decode([CPYSnippet].self, forKey: .snippets)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(index, forKey: .index)
        try container.encode(enable, forKey: .enable)
        try container.encode(title, forKey: .title)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(snippets, forKey: .snippets)
    }

    static func == (lhs: CPYFolder, rhs: CPYFolder) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

// MARK: - Copy
extension CPYFolder {
    func deepCopy() -> CPYFolder {
        let copiedSnippets = snippets.map { CPYSnippet(index: $0.index, enable: $0.enable, title: $0.title, content: $0.content, identifier: $0.identifier) }
        return CPYFolder(index: index, enable: enable, title: title, identifier: identifier, snippets: copiedSnippets)
    }
}

// MARK: - Actions
extension CPYFolder {
    static func create() -> CPYFolder {
        let folder = CPYFolder()
        folder.title = L10n.untitledFolder
        let lastFolder = AppEnvironment.current.dataService.folders.sorted(by: { $0.index < $1.index }).last
        folder.index = (lastFolder?.index ?? -1) + 1
        return folder
    }

    func merge() {
        AppEnvironment.current.dataService.upsertFolder(self)
    }

    func remove() {
        AppEnvironment.current.dataService.deleteFolder(with: identifier)
    }

    func createSnippet() -> CPYSnippet {
        let snippet = CPYSnippet()
        snippet.title = L10n.untitledSnippet
        snippet.index = snippets.count
        return snippet
    }

    func mergeSnippet(_ snippet: CPYSnippet) {
        if !snippets.contains(where: { $0.identifier == snippet.identifier }) {
            snippets.append(snippet)
        }
        merge()
    }

    func insertSnippet(_ snippet: CPYSnippet, index: Int) {
        if let existingIndex = snippets.firstIndex(where: { $0.identifier == snippet.identifier }) {
            snippets.remove(at: existingIndex)
        }
        snippets.insert(snippet, at: index)
        rearrangesSnippetIndex()
        merge()
    }

    func removeSnippet(_ snippet: CPYSnippet) {
        snippets.removeAll(where: { $0.identifier == snippet.identifier })
        rearrangesSnippetIndex()
        merge()
    }

    static func rearrangesIndex(_ folders: [CPYFolder]) {
        for (index, folder) in folders.enumerated() {
            folder.index = index
            folder.merge()
        }
    }

    func rearrangesSnippetIndex() {
        for (index, snippet) in snippets.enumerated() {
            snippet.index = index
        }
    }
}
