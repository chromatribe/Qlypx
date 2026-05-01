//
//  CPYPreferencesWindowController.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2016/02/25.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa

final class CPYPreferencesWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController = CPYPreferencesWindowController(windowNibName: "CPYPreferencesWindowController")
    
    private let viewControllers = [
        NSViewController(nibName: "CPYGeneralPreferenceViewController", bundle: nil),
        NSViewController(nibName: "CPYMenuPreferenceViewController", bundle: nil),
        CPYTypePreferenceViewController(nibName: "CPYTypePreferenceViewController", bundle: nil),
        CPYExcludeAppPreferenceViewController(nibName: "CPYExcludeAppPreferenceViewController", bundle: nil),
        CPYShortcutsPreferenceViewController(nibName: "CPYShortcutsPreferenceViewController", bundle: nil)
    ]

    private enum ToolbarItem: String, CaseIterable {
        case general = "General"
        case menu = "Menu"
        case type = "Type"
        case exclude = "Exclude"
        case shortcuts = "Shortcuts"

        var identifier: NSToolbarItem.Identifier {
            NSToolbarItem.Identifier(self.rawValue)
        }

        var title: String {
            self.rawValue // Can be localized later
        }

        var symbol: String {
            switch self {
            case .general: return "gearshape"
            case .menu: return "list.bullet.rectangle"
            case .type: return "doc.on.doc"
            case .exclude: return "nosign"
            case .shortcuts: return "keyboard"
            }
        }
    }

    // MARK: - Window Life Cycle
    override func windowDidLoad() {
        super.windowDidLoad()
        
        self.window?.collectionBehavior = .canJoinAllSpaces
        
        // Apply modern macOS 11+ window styles
        if #available(macOS 11.0, *) {
            self.window?.toolbarStyle = .preference
        } else {
            self.window?.titlebarAppearsTransparent = true
        }
        self.window?.backgroundColor = NSColor.windowBackgroundColor
        self.window?.isOpaque = true
        self.window?.contentView?.wantsLayer = true
        self.window?.contentView?.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.window?.makeFirstResponder(nil)

        setupToolbar()
        
        // Select initial tab
        if let firstItem = ToolbarItem.allCases.first {
            window?.toolbar?.selectedItemIdentifier = firstItem.identifier
            switchView(index: 0, animate: false)
        }
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(self)
    }

    // MARK: - Setup
    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "PreferencesToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        window?.toolbar = toolbar
    }
}

// MARK: - NSToolbarDelegate
extension CPYPreferencesWindowController: NSToolbarDelegate {
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return ToolbarItem.allCases.map { $0.identifier }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return ToolbarItem.allCases.map { $0.identifier }
    }

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return ToolbarItem.allCases.map { $0.identifier }
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        guard let tabItem = ToolbarItem(rawValue: itemIdentifier.rawValue) else { return nil }
        
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = tabItem.title
        item.paletteLabel = tabItem.title
        item.target = self
        item.action = #selector(toolbarItemSelected(_:))
        
        if #available(macOS 11.0, *) {
            item.image = NSImage(systemSymbolName: tabItem.symbol, accessibilityDescription: tabItem.title)
        } else {
            // Fallback for older macOS versions (though target is 13.0, this is safe)
            item.image = NSImage(named: NSImage.preferencesGeneralName)
        }
        
        return item
    }
    
    @objc private func toolbarItemSelected(_ sender: NSToolbarItem) {
        guard let tabItem = ToolbarItem(rawValue: sender.itemIdentifier.rawValue),
              let index = ToolbarItem.allCases.firstIndex(of: tabItem) else { return }
        switchView(index: index)
    }
}

// MARK: - NSWindow Delegate
extension CPYPreferencesWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if let viewController = viewControllers[2] as? CPYTypePreferenceViewController {
            AppEnvironment.current.defaults.set(viewController.storeTypes, forKey: Constants.UserDefaults.storeTypes)
            AppEnvironment.current.defaults.synchronize()
        }
        if let window = window {
            window.makeFirstResponder(nil)
            window.endEditing(for: nil)
        }
        NSApp.deactivate()
    }
}

// MARK: - Layout
private extension CPYPreferencesWindowController {
    
    func switchView(index: Int, animate: Bool = false) {
        guard index >= 0 && index < viewControllers.count else { return }
        let newView = viewControllers[index].view
        
        guard let currentWindow = window, let contentView = currentWindow.contentView else { return }

        // 1. レイヤーと背景色の設定
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        currentWindow.backgroundColor = NSColor.windowBackgroundColor
        currentWindow.isOpaque = true
        
        // 2. 念のためフォーカスを外す
        currentWindow.makeFirstResponder(nil)
        
        // 3. ビューの入れ替え
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.addSubview(newView)
        newView.frame = contentView.bounds
        newView.autoresizingMask = [.width, .height]
        
        // 4. 新しいフレームの計算と適用
        var newFrame = currentWindow.frameRect(forContentRect: newView.frame)
        let oldFrame = currentWindow.frame
        newFrame.origin.y = oldFrame.origin.y + oldFrame.size.height - newFrame.size.height
        newFrame.origin.x = oldFrame.origin.x
        
        // アニメーションを無効化（ちらつき防止の確実な策）
        currentWindow.setFrame(newFrame, display: true, animate: animate)
        
        // 5. 最後にフォーカスを移す
        DispatchQueue.main.async {
            currentWindow.makeFirstResponder(newView)
        }
    }
}
