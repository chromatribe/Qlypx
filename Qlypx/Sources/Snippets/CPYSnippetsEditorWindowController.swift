//
//  CPYSnippetsEditorWindowController.swift
//  Qlypx
//

import Cocoa
import SwiftUI
import Combine
import Magnet
import KeyHolder
import UniformTypeIdentifiers

// MARK: - Controller
final class CPYSnippetsEditorWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController: CPYSnippetsEditorWindowController = {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.editSnippets
        window.center()
        let controller = CPYSnippetsEditorWindowController(window: window)
        controller.setupWindow()
        return controller
    }()

    // MARK: - Setup
    private func setupWindow() {
        guard let window = self.window else { return }
        
        window.collectionBehavior = .canJoinAllSpaces
        window.backgroundColor = NSColor.windowBackgroundColor
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        
        // Host SwiftUI View
        let rootView = SnippetsEditorView()
        let hostingController = NSHostingController(rootView: rootView)
        
        DispatchQueue.main.async {
            window.contentView = hostingController.view
        }
        
        // Window setup
        window.minSize = NSSize(width: 800, height: 600)
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }
}

// MARK: - ViewModel
final class SnippetsStore: ObservableObject {
    @Published var folders: [CPYFolder] = []
    @Published var selectedItemId: String?
    
    init() {
        refresh()
    }
    
    func refresh() {
        DispatchQueue.main.async {
            self.folders = AppEnvironment.current.dataService.folders
                .sorted(by: { $0.index < $1.index })
                .map { $0.deepCopy() }
            self.objectWillChange.send()
        }
    }
    
    var selectedFolder: CPYFolder? {
        guard let id = selectedItemId else { return nil }
        return folders.first(where: { $0.id == id })
    }
    
    var selectedSnippet: CPYSnippet? {
        guard let id = selectedItemId else { return nil }
        for folder in folders {
            if let snippet = folder.snippets.first(where: { $0.id == id }) {
                return snippet
            }
        }
        return nil
    }
    
    // MARK: - Actions
    func addFolder() {
        let baseTitle = L10n.untitledFolder
        let folder = CPYFolder.create()
        folder.title = uniqueFolderName(base: baseTitle)
        folder.merge()
        
        DispatchQueue.main.async {
            self.folders.append(folder)
            self.selectedItemId = folder.id
            self.objectWillChange.send()
        }
    }
    
    func addSnippet() {
        // Use the current selection to determine the parent folder
        var targetFolder: CPYFolder?
        if let folder = selectedFolder {
            targetFolder = folder
        } else if let snippet = selectedSnippet {
            targetFolder = folders.first(where: { $0.snippets.contains(where: { $0.id == snippet.id }) })
        }
        
        // If no folder selected, default to the first folder
        if targetFolder == nil {
            targetFolder = folders.first
        }
        
        guard let folder = targetFolder else { return }
        
        let baseTitle = L10n.untitledSnippet
        let snippet = folder.createSnippet()
        snippet.title = uniqueSnippetName(in: folder, base: baseTitle)
        folder.snippets.append(snippet)
        folder.mergeSnippet(snippet)
        
        DispatchQueue.main.async {
            self.folders = self.folders // Notify deep change
            self.selectedItemId = snippet.id
            self.objectWillChange.send()
        }
    }
    
    func deleteSelectedItem() {
        guard let id = selectedItemId else { return }
        
        if let folder = folders.first(where: { $0.id == id }) {
            folders.removeAll(where: { $0.id == id })
            folder.remove()
            AppEnvironment.current.hotKeyService.unregisterSnippetHotKey(with: folder.identifier)
            DispatchQueue.main.async {
                self.selectedItemId = nil
                self.objectWillChange.send()
            }
        } else {
            for folder in folders {
                if let index = folder.snippets.firstIndex(where: { $0.id == id }) {
                    let snippet = folder.snippets.remove(at: index)
                    snippet.remove()
                    DispatchQueue.main.async {
                        self.folders = self.folders
                        self.selectedItemId = nil
                        self.objectWillChange.send()
                    }
                    return
                }
            }
        }
    }
    
    func toggleStatus() {
        guard let id = selectedItemId else { return }
        
        if let folder = folders.first(where: { $0.id == id }) {
            folder.enable = !folder.enable
            folder.merge()
        } else if let snippet = selectedSnippet {
            snippet.enable = !snippet.enable
            snippet.merge()
        }
        DispatchQueue.main.async {
            self.folders = self.folders
            self.objectWillChange.send()
        }
    }
    
    func importCSV(from url: URL) {
        do {
            let csvString = try String(contentsOf: url, encoding: .utf8)
            let items = SnippetCSVService.shared.parse(csvString: csvString)
            for item in items {
                let folder: CPYFolder
                if let existingFolder = self.folders.first(where: { $0.title == item.folder }) {
                    folder = existingFolder
                } else {
                    folder = CPYFolder.create()
                    folder.title = item.folder
                    self.folders.append(folder)
                    folder.merge()
                }
                let snippet = folder.createSnippet()
                snippet.title = item.title
                snippet.content = item.content
                folder.snippets.append(snippet)
                folder.mergeSnippet(snippet)
            }
            refresh()
        } catch {
            QlyLogger.error("Failed to import CSV: \(error)", log: .menu)
        }
    }
    
    func exportCSV(to url: URL) {
        let csvString = SnippetCSVService.shared.export(folders: self.folders)
        do {
            try csvString.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            QlyLogger.error("Failed to export CSV: \(error)", log: .menu)
        }
    }
    
    // MARK: - Helpers
    private func uniqueFolderName(base: String) -> String {
        var name = base
        var count = 1
        while folders.contains(where: { $0.title == name }) {
            name = "\(base)_\(count)"
            count += 1
        }
        return name
    }
    
    private func uniqueSnippetName(in folder: CPYFolder, base: String) -> String {
        var name = base
        var count = 1
        // Search current in-memory snippets for this folder
        while folder.snippets.contains(where: { $0.title == name }) {
            name = "\(base)_\(count)"
            count += 1
        }
        return name
    }
}

// MARK: - Views
struct SnippetsEditorView: View {
    @StateObject private var store = SnippetsStore()
    
    var body: some View {
        NavigationSplitView {
            SnippetsSidebarView(store: store)
                .navigationTitle(L10n.snippet)
        } detail: {
            if let snippet = store.selectedSnippet {
                SnippetDetailView(snippet: snippet)
                    .id(snippet.id)
            } else if let folder = store.selectedFolder {
                FolderDetailView(folder: folder)
                    .id(folder.id)
            } else {
                Text(L10n.snippet)
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(action: store.addFolder) {
                    Label(L10n.addFolder, systemImage: "folder.badge.plus")
                }
                .help(L10n.addFolder)
                
                Button(action: store.addSnippet) {
                    Label(L10n.addSnippet, systemImage: "doc.badge.plus")
                }
                .help(L10n.addSnippet)
                
                Button(action: store.deleteSelectedItem) {
                    Label(L10n.delete, systemImage: "trash")
                }
                .disabled(store.selectedItemId == nil)
                .help(L10n.delete)
                
                Button(action: store.toggleStatus) {
                    Label(L10n.enableDisable, systemImage: "switch.2")
                }
                .disabled(store.selectedItemId == nil)
                .help(L10n.enableDisable)
                
                Divider()
                
                Button(action: importCSV) {
                    Label(L10n.importCsv, systemImage: "square.and.arrow.down")
                }
                .help(L10n.importCsv)
                
                Button(action: exportCSV) {
                    Label(L10n.exportCsv, systemImage: "square.and.arrow.up")
                }
                .help(L10n.exportCsv)
            }
        }
    }
    
    private func importCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            store.importCSV(from: url)
        }
    }
    
    private func exportCSV() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "snippets.csv"
        if panel.runModal() == .OK, let url = panel.url {
            store.exportCSV(to: url)
        }
    }
}

struct SnippetsSidebarView: View {
    @ObservedObject var store: SnippetsStore
    @State private var expandedFolderIds = Set<String>()
    
    var body: some View {
        List(selection: $store.selectedItemId) {
            ForEach(store.folders) { folder in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedFolderIds.contains(folder.id) },
                        set: { isExpanded in
                            if isExpanded {
                                expandedFolderIds.insert(folder.id)
                            } else {
                                expandedFolderIds.remove(folder.id)
                            }
                        }
                    )
                ) {
                    ForEach(folder.snippets) { snippet in
                        SnippetRowView(snippet: snippet)
                            .tag(snippet.id)
                    }
                } label: {
                    FolderRowView(folder: folder)
                        .tag(folder.id)
                }
            }
        }
        .listStyle(.sidebar)
        .onAppear {
            // Expand all folders on initial appear
            expandedFolderIds = Set(store.folders.map { $0.id })
        }
        .onChange(of: store.folders.count) { _ in
            // When a new folder is added, ensure it is expanded
            let allIds = Set(store.folders.map { $0.id })
            expandedFolderIds = expandedFolderIds.union(allIds)
        }
    }
}

struct FolderRowView: View {
    @ObservedObject var folder: CPYFolder
    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundColor(.accentColor)
            Text(folder.title)
                .fontWeight(.medium)
                .opacity(folder.enable ? 1.0 : 0.5)
        }
        .contentShape(Rectangle())
    }
}

struct SnippetRowView: View {
    @ObservedObject var snippet: CPYSnippet
    var body: some View {
        HStack {
            Image(systemName: "doc")
                .foregroundColor(.secondary)
            Text(snippet.title)
                .opacity(snippet.enable ? 1.0 : 0.5)
        }
        .contentShape(Rectangle())
    }
}

struct SnippetDetailView: View {
    @ObservedObject var snippet: CPYSnippet
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField(L10n.untitledSnippet, text: $snippet.title)
                .font(.title2)
                .textFieldStyle(.plain)
                .onChange(of: snippet.title) { _ in snippet.merge() }
            Divider()
            TextEditor(text: $snippet.content)
                .font(.system(.body, design: .monospaced))
                .onChange(of: snippet.content) { _ in snippet.merge() }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(24)
    }
}

struct FolderDetailView: View {
    @ObservedObject var folder: CPYFolder
    @State private var keyCombo: Magnet.KeyCombo?
    
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            Spacer()
            VStack(spacing: 8) {
                TextField(L10n.untitledFolder, text: $folder.title)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .onChange(of: folder.title) { _ in folder.merge() }
                Text(L10n.shortcuts).font(.caption).foregroundColor(.secondary)
            }
            ShortcutRecordView(keyCombo: $keyCombo) { newKeyCombo in
                if let combo = newKeyCombo {
                    AppEnvironment.current.hotKeyService.registerSnippetHotKey(with: folder.identifier, keyCombo: combo)
                } else {
                    AppEnvironment.current.hotKeyService.unregisterSnippetHotKey(with: folder.identifier)
                }
            }
            .frame(width: 250, height: 30)
            Spacer()
        }
        .padding(24)
        .onAppear {
            keyCombo = AppEnvironment.current.hotKeyService.snippetKeyCombo(forIdentifier: folder.identifier)
        }
    }
}

struct ShortcutRecordView: NSViewRepresentable {
    @Binding var keyCombo: KeyCombo?
    var onKeyComboChange: (KeyCombo?) -> Void
    func makeNSView(context: Context) -> RecordView {
        let recordView = RecordView(frame: .zero)
        recordView.delegate = context.coordinator
        return recordView
    }
    func updateNSView(_ nsView: RecordView, context: Context) {
        if nsView.keyCombo != keyCombo { nsView.keyCombo = keyCombo }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, RecordViewDelegate {
        var parent: ShortcutRecordView
        init(_ parent: ShortcutRecordView) { self.parent = parent }
        func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool { true }
        func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool { true }
        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            parent.keyCombo = keyCombo
            parent.onKeyComboChange(keyCombo)
        }
        func recordViewDidEndRecording(_ recordView: RecordView) {}
    }
}
