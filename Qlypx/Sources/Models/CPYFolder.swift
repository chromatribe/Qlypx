//
//  CPYFolder.swift
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

final class CPYFolder: Codable, Equatable, Hashable {
    var index: Int = 0
    var enable: Bool = true
    var title: String = ""
    var identifier: String = UUID().uuidString
    var snippets: [CPYSnippet] = []

    init(index: Int = 0, enable: Bool = true, title: String = "", identifier: String = UUID().uuidString, snippets: [CPYSnippet] = []) {
        self.index = index
        self.enable = enable
        self.title = title
        self.identifier = identifier
        self.snippets = snippets
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
        folder.title = "untitled folder"
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
        snippet.title = "untitled snippet"
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
