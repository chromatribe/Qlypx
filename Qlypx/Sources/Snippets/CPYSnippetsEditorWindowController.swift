//
//  CPYSnippetsEditorWindowController.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2016/05/18.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa
import KeyHolder
import Magnet
import UniformTypeIdentifiers

final class CPYSnippetsEditorWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController = CPYSnippetsEditorWindowController(windowNibName: "CPYSnippetsEditorWindowController")
    @IBOutlet private weak var splitView: CPYSplitView!
    @IBOutlet private weak var folderSettingView: NSView!
    @IBOutlet private weak var folderTitleTextField: NSTextField!
    @IBOutlet private weak var folderShortcutRecordView: RecordView! {
        didSet {
            folderShortcutRecordView.delegate = self
        }
    }
    @IBOutlet private var textView: CPYPlaceHolderTextView! {
        didSet {
            textView.font = NSFont.systemFont(ofSize: 14)
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.enabledTextCheckingTypes = 0
            textView.isRichText = false
            textView.placeHolderText = L10n.pleaseFillInTheContentsOfTheSnippet
        }
    }
    @IBOutlet private weak var outlineView: NSOutlineView! {
        didSet {
            // Enable Drag and Drop
            outlineView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)])
        }
    }

    private var folders = [CPYFolder]()
    private var selectedSnippet: CPYSnippet? {
        guard let snippet = outlineView.item(atRow: outlineView.selectedRow) as? CPYSnippet else { return nil }
        return snippet
    }
    private var selectedFolder: CPYFolder? {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else { return nil }
        if let folder = outlineView.parent(forItem: item) as? CPYFolder {
            return folder
        } else if let folder = item as? CPYFolder {
            return folder
        }
        return nil
    }

    private enum ToolbarItem: String, CaseIterable {
        case addFolder = "Add Folder"
        case addSnippet = "Add Snippet"
        case delete = "Delete"
        case changeStatus = "Enable/Disable"
        case importCSV = "Import CSV"
        case exportCSV = "Export CSV"

        var identifier: NSToolbarItem.Identifier { NSToolbarItem.Identifier(self.rawValue) }
        var title: String {
            return NSLocalizedString(self.rawValue, comment: "")
        }
        var symbol: String {
            switch self {
            case .addFolder: return "folder.badge.plus"
            case .addSnippet: return "doc.badge.plus"
            case .delete: return "trash"
            case .changeStatus: return "switch.2"
            case .importCSV: return "square.and.arrow.down"
            case .exportCSV: return "square.and.arrow.up"
            }
        }
    }

    // MARK: - Window Life Cycle
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.collectionBehavior = NSWindow.CollectionBehavior.canJoinAllSpaces
        self.window?.backgroundColor = NSColor.windowBackgroundColor
        if #available(macOS 11.0, *) {
            self.window?.toolbarStyle = .unified
        } else {
            self.window?.titlebarAppearsTransparent = true
        }
        
        setupToolbar()
        
        folders = AppEnvironment.current.dataService.folders
                    .sorted(by: { $0.index < $1.index })
                    .map { $0.deepCopy() }
        outlineView.reloadData()
        // Select first folder
        if let folder = folders.first {
            outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
            changeItemFocus()
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }
}

// MARK: - IBActions
extension CPYSnippetsEditorWindowController {
    @IBAction private func addSnippetButtonTapped(_ sender: AnyObject) {
        guard let folder = selectedFolder else {
            NSSound.beep()
            return
        }
        let snippet = folder.createSnippet()
        folder.snippets.append(snippet)
        folder.mergeSnippet(snippet)
        outlineView.reloadData()
        outlineView.expandItem(folder)
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: snippet)), byExtendingSelection: false)
        changeItemFocus()
    }

    @IBAction private func addFolderButtonTapped(_ sender: AnyObject) {
        let folder = CPYFolder.create()
        folders.append(folder)
        folder.merge()
        outlineView.reloadData()
        outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
        changeItemFocus()
    }

    @IBAction private func deleteButtonTapped(_ sender: AnyObject) {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            NSSound.beep()
            return
        }

        let alert = NSAlert()
        alert.messageText = L10n.deleteItem
        alert.informativeText = L10n.areYouSureWantToDeleteThisItem
        alert.addButton(withTitle: L10n.deleteItem)
        alert.addButton(withTitle: L10n.cancel)
        NSApp.activate(ignoringOtherApps: true)
        let result = alert.runModal()
        if result != NSApplication.ModalResponse.alertFirstButtonReturn { return }

        if let folder = item as? CPYFolder {
            folders.removeObject(folder)
            folder.remove()
            AppEnvironment.current.hotKeyService.unregisterSnippetHotKey(with: folder.identifier)
        } else if let snippet = item as? CPYSnippet, let folder = outlineView.parent(forItem: item) as? CPYFolder, let index = folder.snippets.firstIndex(of: snippet) {
            folder.snippets.remove(at: index)
            snippet.remove()
        }
        outlineView.reloadData()
        changeItemFocus()
    }

    @IBAction private func changeStatusButtonTapped(_ sender: AnyObject) {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            NSSound.beep()
            return
        }
        if let folder = item as? CPYFolder {
            folder.enable = !folder.enable
            folder.merge()
        } else if let snippet = item as? CPYSnippet {
            snippet.enable = !snippet.enable
            snippet.merge()
        }
        outlineView.reloadData()
        changeItemFocus()
    }

    @objc private func importCSVButtonTapped(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModal(for: self.window!) { [weak self] result in
            guard let self = self, result == .OK, let url = panel.url else { return }
            
            do {
                let csvString = try String(contentsOf: url, encoding: .utf8)
                let items = SnippetCSVService.shared.parse(csvString: csvString)
                
                for item in items {
                    // Find or create folder
                    let folder: CPYFolder
                    if let existingFolder = self.folders.first(where: { $0.title == item.folder }) {
                        folder = existingFolder
                    } else {
                        folder = CPYFolder.create()
                        folder.title = item.folder
                        self.folders.append(folder)
                        folder.merge()
                    }
                    
                    // Create snippet
                    let snippet = folder.createSnippet()
                    snippet.title = item.title
                    snippet.content = item.content
                    folder.snippets.append(snippet)
                    folder.mergeSnippet(snippet)
                }
                
                self.outlineView.reloadData()
                QlyLogger.info("Imported \(items.count) snippets from CSV", log: .menu)
                
            } catch {
                QlyLogger.error("Failed to import CSV: \(error)", log: .menu)
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    @objc private func exportCSVButtonTapped(_ sender: AnyObject) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "snippets.csv"
        
        panel.beginSheetModal(for: self.window!) { [weak self] result in
            guard let self = self, result == .OK, let url = panel.url else { return }
            
            let csvString = SnippetCSVService.shared.export(folders: self.folders)
            do {
                try csvString.write(to: url, atomically: true, encoding: .utf8)
                QlyLogger.info("Exported snippets to CSV", log: .menu)
            } catch {
                QlyLogger.error("Failed to export CSV: \(error)", log: .menu)
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }

    // MARK: - Toolbar Setup
    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "SnippetsToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = true
        toolbar.autosavesConfiguration = true
        window?.toolbar = toolbar
    }
}

// MARK: - Item Selected
private extension CPYSnippetsEditorWindowController {
    func changeItemFocus() {
        // Reset TextView Undo/Redo history
        textView.undoManager?.removeAllActions()
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else {
            folderSettingView.isHidden = true
            textView.isHidden = true
            folderShortcutRecordView.keyCombo = nil
            folderTitleTextField.stringValue = ""
            return
        }
        if let folder = item as? CPYFolder {
            textView.string = ""
            folderTitleTextField.stringValue = folder.title
            folderShortcutRecordView.keyCombo = AppEnvironment.current.hotKeyService.snippetKeyCombo(forIdentifier: folder.identifier)
            folderSettingView.isHidden = false
            textView.isHidden = true
        } else if let snippet = item as? CPYSnippet {
            textView.string = snippet.content
            folderTitleTextField.stringValue = ""
            folderShortcutRecordView.keyCombo = nil
            folderSettingView.isHidden = true
            textView.isHidden = false
        }
    }
}

// MARK: - NSSplitView Delegate
extension CPYSnippetsEditorWindowController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMinimumPosition + 150
    }

    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        return proposedMaximumPosition / 2
    }
}

// MARK: - NSOutlineView DataSource
extension CPYSnippetsEditorWindowController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return Int(folders.count)
        } else if let folder = item as? CPYFolder {
            return Int(folder.snippets.count)
        }
        return 0
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let folder = item as? CPYFolder {
            return !folder.snippets.isEmpty
        }
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return folders[index]
        } else if let folder = item as? CPYFolder {
            return folder.snippets[index]
        }
        return ""
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        if let folder = item as? CPYFolder {
            return folder.title
        } else if let snippet = item as? CPYSnippet {
            return snippet.title
        }
        return ""
    }

    // MARK: - Drag and Drop
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        let pasteboardItem = NSPasteboardItem()
        if let folder = item as? CPYFolder, let index = folders.firstIndex(of: folder) {
            let draggedData = CPYDraggedData(type: .folder, folderIdentifier: folder.identifier, snippetIdentifier: nil, index: index)
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: true)
                pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType))
            } catch {
                QlyLogger.error("Failed to archive dragged folder data: \(error)", log: .menu)
            }
        } else if let snippet = item as? CPYSnippet, let folder = outlineView.parent(forItem: snippet) as? CPYFolder {
            guard let index = folder.snippets.firstIndex(of: snippet) else { return nil }
            let draggedData = CPYDraggedData(type: .snippet, folderIdentifier: folder.identifier, snippetIdentifier: snippet.identifier, index: Int(index))
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: draggedData, requiringSecureCoding: true)
                pasteboardItem.setData(data, forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType))
            } catch {
                QlyLogger.error("Failed to archive dragged snippet data: \(error)", log: .menu)
            }
        } else {
            return nil
        }
        return pasteboardItem
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        let pasteboard = info.draggingPasteboard
        guard let data = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)) else { return NSDragOperation() }
        
        do {
            guard let draggedData = try NSKeyedUnarchiver.unarchivedObject(ofClass: CPYDraggedData.self, from: data) else { return NSDragOperation() }

            switch draggedData.type {
            case .folder where item == nil:
                return .move
            case .snippet where item is CPYFolder:
                return .move
            default:
                return NSDragOperation()
            }
        } catch {
            QlyLogger.error("Failed to unarchive dragged data (validate): \(error)", log: .menu)
            return NSDragOperation()
        }
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        let pasteboard = info.draggingPasteboard
        guard let data = pasteboard.data(forType: NSPasteboard.PasteboardType(rawValue: Constants.Common.draggedDataType)) else { return false }
        
        do {
            guard let draggedData = try NSKeyedUnarchiver.unarchivedObject(ofClass: CPYDraggedData.self, from: data) else { return false }

            switch draggedData.type {
            case .folder where index != draggedData.index:
                guard index >= 0 else { return false }
                guard let folder = folders.first(where: { $0.identifier == draggedData.folderIdentifier }) else { return false }
                folders.insert(folder, at: index)
                let removedIndex = (index < draggedData.index) ? draggedData.index + 1 : draggedData.index
                folders.remove(at: removedIndex)
                outlineView.reloadData()
                outlineView.selectRowIndexes(IndexSet(integer: outlineView.row(forItem: folder)), byExtendingSelection: false)
                CPYFolder.rearrangesIndex(folders)
                changeItemFocus()
                return true
            case .snippet:
                guard let fromFolder = folders.first(where: { $0.identifier == draggedData.folderIdentifier }) else { return false }
                guard let toFolder = item as? CPYFolder else { return false }
                guard let snippet = fromFolder.snippets.first(where: { $0.identifier == draggedData.snippetIdentifier }) else { return false }

                if fromFolder.identifier == toFolder.identifier {
                    guard index >= 0 else { return false }
                    if index == draggedData.index { return false }
                    // Move to same folder
                    fromFolder.snippets.insert(snippet, at: index)
                    let removedIndex = (index < draggedData.index) ? draggedData.index + 1 : draggedData.index
                    fromFolder.snippets.remove(at: removedIndex)
                    outlineView.reloadData()
                    outlineView.selectRowIndexes(NSIndexSet(index: outlineView.row(forItem: snippet)) as IndexSet, byExtendingSelection: false)
                    fromFolder.rearrangesSnippetIndex()
                    changeItemFocus()
                    return true
                } else {
                    // Move to other folder
                    let index = max(0, index)
                    toFolder.snippets.insert(snippet, at: index)
                    fromFolder.snippets.remove(at: draggedData.index)
                    outlineView.reloadData()
                    outlineView.expandItem(toFolder)
                    outlineView.selectRowIndexes(NSIndexSet(index: outlineView.row(forItem: snippet)) as IndexSet, byExtendingSelection: false)
                    toFolder.insertSnippet(snippet, index: index)
                    fromFolder.removeSnippet(snippet)
                    changeItemFocus()
                    return true
                }
            default: return false
            }
        } catch {
            QlyLogger.error("Failed to unarchive dragged data (accept): \(error)", log: .menu)
            return false
        }
    }
}

// MARK: - NSOutlineView Delegate
extension CPYSnippetsEditorWindowController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, item: Any) {
        guard let cell = cell as? CPYSnippetsEditorCell else { return }
        if let folder = item as? CPYFolder {
            cell.iconType = .folder
            cell.isItemEnabled = folder.enable
        } else if let snippet = item as? CPYSnippet {
            cell.iconType = .none
            cell.isItemEnabled = snippet.enable
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        changeItemFocus()
    }

    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let text = fieldEditor.string
        guard !text.isEmpty else { return false }
        guard let outlineView = control as? NSOutlineView else { return false }
        guard let item = outlineView.item(atRow: outlineView.selectedRow) else { return false }
        if let folder = item as? CPYFolder {
            folder.title = text
            folder.merge()
        } else if let snippet = item as? CPYSnippet {
            snippet.title = text
            snippet.merge()
        }
        changeItemFocus()
        return true
    }
}

// MARK: - NSTextView Delegate
extension CPYSnippetsEditorWindowController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
        guard let replacementString = replacementString else { return false }
        let text = textView.string
        guard let snippet = selectedSnippet else { return false }
        let string = (text as NSString).replacingCharacters(in: affectedCharRange, with: replacementString)
        snippet.content = string
        snippet.merge()
        return true
    }
}

// MARK: - RecordView Delegate
extension CPYSnippetsEditorWindowController: RecordViewDelegate {
    func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
        guard selectedFolder != nil else { return false }
        return true
    }

    func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
        guard selectedFolder != nil else { return false }
        return true
    }

    func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
        guard let selectedFolder = selectedFolder else { return }
        guard let keyCombo = keyCombo else {
            AppEnvironment.current.hotKeyService.unregisterSnippetHotKey(with: selectedFolder.identifier)
            return
        }
        AppEnvironment.current.hotKeyService.registerSnippetHotKey(with: selectedFolder.identifier, keyCombo: keyCombo)
    }

    func recordViewDidEndRecording(_ recordView: RecordView) {}
}

// MARK: - NSToolbarDelegate
extension CPYSnippetsEditorWindowController: NSToolbarDelegate {
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return ToolbarItem.allCases.map { $0.identifier } + [.space, .flexibleSpace]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.flexibleSpace] + ToolbarItem.allCases.map { $0.identifier } + [.flexibleSpace]
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let tabItem = ToolbarItem(rawValue: itemIdentifier.rawValue) else { return nil }
        
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tabItem.title
        item.paletteLabel = tabItem.title
        item.target = self
        
        switch tabItem {
        case .addFolder: item.action = #selector(addFolderButtonTapped(_:))
        case .addSnippet: item.action = #selector(addSnippetButtonTapped(_:))
        case .delete: item.action = #selector(deleteButtonTapped(_:))
        case .changeStatus: item.action = #selector(changeStatusButtonTapped(_:))
        case .importCSV: item.action = #selector(importCSVButtonTapped(_:))
        case .exportCSV: item.action = #selector(exportCSVButtonTapped(_:))
        }
        
        if #available(macOS 11.0, *) {
            item.image = NSImage(systemSymbolName: tabItem.symbol, accessibilityDescription: tabItem.title)
        }
        
        return item
    }
}
