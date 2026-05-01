//
//  HotKeyService.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2016/11/19.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation
import Cocoa
import Magnet

final class HotKeyService: NSObject {

    // MARK: - Properties
    static var defaultKeyCombos: [String: Any] = {
        // MainMenu:    ⌘ + Shift + V
        // HistoryMenu: ⌘ + Control + V
        // SnipeetMenu: ⌘ + Shift B
        return [Constants.Menu.clip: ["keyCode": 9, "modifiers": 768],
                Constants.Menu.history: ["keyCode": 9, "modifiers": 4352],
                Constants.Menu.snippet: ["keyCode": 11, "modifiers": 768]]
    }()

    fileprivate(set) var mainKeyCombo: KeyCombo?
    fileprivate(set) var historyKeyCombo: KeyCombo?
    fileprivate(set) var snippetKeyCombo: KeyCombo?
    fileprivate(set) var clearHistoryKeyCombo: KeyCombo?

}

// MARK: - Actions
extension HotKeyService {
    @objc func popupMainMenu() {
        AppEnvironment.current.menuManager.popUpMenu(.main)
    }

    @objc func popupHistoryMenu() {
        AppEnvironment.current.menuManager.popUpMenu(.history)
    }

    @objc func popUpSnippetMenu() {
        AppEnvironment.current.menuManager.popUpMenu(.snippet)
    }

    @objc func popUpClearHistoryAlert() {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.clearAllHistory()
    }
}

// MARK: - Setup
extension HotKeyService {
    func setupDefaultHotKeys() {
        // Migration new framework
        if !AppEnvironment.current.defaults.bool(forKey: Constants.HotKey.migrateNewKeyCombo) {
            migrationKeyCombos()
            AppEnvironment.current.defaults.set(true, forKey: Constants.HotKey.migrateNewKeyCombo)
            AppEnvironment.current.defaults.synchronize()
        }
        // Snippet hotkey
        setupSnippetHotKeys()

        // Main menu
        change(with: .main, keyCombo: savedKeyCombo(forKey: Constants.HotKey.mainKeyCombo))
        // History menu
        change(with: .history, keyCombo: savedKeyCombo(forKey: Constants.HotKey.historyKeyCombo))
        // Snippet menu
        change(with: .snippet, keyCombo: savedKeyCombo(forKey: Constants.HotKey.snippetKeyCombo))
        // Clear History
        changeClearHistoryKeyCombo(savedKeyCombo(forKey: Constants.HotKey.clearHistoryKeyCombo))
    }

    func change(with type: MenuType, keyCombo: KeyCombo?) {
        QlyLogger.debug("Changing HotKey for \(type.rawValue) to \(String(describing: keyCombo))", log: .hotkey)
        switch type {
        case .main:
            mainKeyCombo = keyCombo
        case .history:
            historyKeyCombo = keyCombo
        case .snippet:
            snippetKeyCombo = keyCombo
        }
        register(with: type, keyCombo: keyCombo)
    }

    func changeClearHistoryKeyCombo(_ keyCombo: KeyCombo?) {
        QlyLogger.debug("Changing ClearHistory HotKey to \(String(describing: keyCombo))", log: .hotkey)
        clearHistoryKeyCombo = keyCombo
        if let keyCombo = keyCombo {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: keyCombo, requiringSecureCoding: false)
                AppEnvironment.current.defaults.set(data, forKey: Constants.HotKey.clearHistoryKeyCombo)
            } catch {
                QlyLogger.error("Failed to archive ClearHistory KeyCombo: \(error)", log: .hotkey)
            }
        } else {
            AppEnvironment.current.defaults.removeObject(forKey: Constants.HotKey.clearHistoryKeyCombo)
        }
        // Reset hotkey
        HotKeyCenter.shared.unregisterHotKey(with: "ClearHistory")
        // Register new hotkey
        guard let keyCombo = keyCombo else { return }
        let hotkey = HotKey(identifier: "ClearHistory", keyCombo: keyCombo, target: self, action: #selector(HotKeyService.popUpClearHistoryAlert))
        hotkey.register()
    }

    private func savedKeyCombo(forKey key: String) -> KeyCombo? {
        guard let data = AppEnvironment.current.defaults.object(forKey: key) as? Data else { return nil }
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            let keyCombo = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? KeyCombo
            return keyCombo
        } catch {
            QlyLogger.error("Failed to unarchive KeyCombo for key \(key): \(error)", log: .hotkey)
            return nil
        }
    }
}

// MARK: - Register
private extension HotKeyService {
    func register(with type: MenuType, keyCombo: KeyCombo?) {
        save(with: type, keyCombo: keyCombo)
        // Reset hotkey
        QlyLogger.debug("Unregistering HotKey for \(type.rawValue)", log: .hotkey)
        HotKeyCenter.shared.unregisterHotKey(with: type.rawValue)
        // Register new hotkey
        guard let keyCombo = keyCombo else { 
            QlyLogger.debug("No KeyCombo for \(type.rawValue), skipping registration", log: .hotkey)
            return 
        }
        QlyLogger.debug("Registering HotKey for \(type.rawValue): \(keyCombo)", log: .hotkey)
        let hotKey = HotKey(identifier: type.rawValue, keyCombo: keyCombo, target: self, action: type.hotKeySelector)
        if hotKey.register() {
            QlyLogger.debug("Successfully registered HotKey for \(type.rawValue)", log: .hotkey)
        } else {
            QlyLogger.error("Failed to register HotKey for \(type.rawValue)", log: .hotkey)
        }
    }

    func save(with type: MenuType, keyCombo: KeyCombo?) {
        if let keyCombo = keyCombo {
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: keyCombo, requiringSecureCoding: false)
                AppEnvironment.current.defaults.set(data, forKey: type.userDefaultsKey)
            } catch {
                QlyLogger.error("Failed to archive KeyCombo for \(type.rawValue): \(error)", log: .hotkey)
            }
        } else {
            AppEnvironment.current.defaults.removeObject(forKey: type.userDefaultsKey)
        }
    }
}

// MARK: - Migration
private extension HotKeyService {
    /**
     *  Migration for changing the storage with v1.1.0
     *  Changed framework, PTHotKey to Magnet
     */
    func migrationKeyCombos() {
        guard let keyCombos = AppEnvironment.current.defaults.object(forKey: Constants.UserDefaults.hotKeys) as? [String: Any] else { return }

        // Main menu
        if let (keyCode, modifiers) = parse(with: keyCombos, forKey: Constants.Menu.clip) {
            if let keyCombo = KeyCombo(QWERTYKeyCode: keyCode, carbonModifiers: modifiers) {
                save(with: .main, keyCombo: keyCombo)
            }
        }
        // History menu
        if let (keyCode, modifiers) = parse(with: keyCombos, forKey: Constants.Menu.history) {
            if let keyCombo = KeyCombo(QWERTYKeyCode: keyCode, carbonModifiers: modifiers) {
                save(with: .history, keyCombo: keyCombo)
            }
        }
        // Snippet menu
        if let (keyCode, modifiers) = parse(with: keyCombos, forKey: Constants.Menu.snippet) {
            if let keyCombo = KeyCombo(QWERTYKeyCode: keyCode, carbonModifiers: modifiers) {
                save(with: .snippet, keyCombo: keyCombo)
            }
        }
    }

    func parse(with keyCombos: [String: Any], forKey key: String) -> (Int, Int)? {
        guard let combos = keyCombos[key] as? [String: Any] else { return nil }
        guard let keyCode = combos["keyCode"] as? Int, let modifiers = combos["modifiers"] as? Int else { return nil }
        return (keyCode, modifiers)
    }
}

// MARK: - Snippet HotKey
extension HotKeyService {
    private var folderKeyCombos: [String: KeyCombo]? {
        get {
            guard let data = AppEnvironment.current.defaults.object(forKey: Constants.HotKey.folderKeyCombos) as? Data else { return nil }
            do {
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
                unarchiver.requiresSecureCoding = false
                return unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? [String: KeyCombo]
            } catch {
                QlyLogger.error("Failed to unarchive folderKeyCombos: \(error)", log: .hotkey)
                return nil
            }
        }
        set {
            if let value = newValue {
                do {
                    let data = try NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: false)
                    AppEnvironment.current.defaults.set(data, forKey: Constants.HotKey.folderKeyCombos)
                } catch {
                    QlyLogger.error("Failed to archive folderKeyCombos: \(error)", log: .hotkey)
                }
            } else {
                AppEnvironment.current.defaults.removeObject(forKey: Constants.HotKey.folderKeyCombos)
            }
            AppEnvironment.current.defaults.synchronize()
        }
    }

    func snippetKeyCombo(forIdentifier identifier: String) -> KeyCombo? {
        return folderKeyCombos?[identifier]
    }

    func registerSnippetHotKey(with identifier: String, keyCombo: KeyCombo) {
        // Reset hotkey
        unregisterSnippetHotKey(with: identifier)
        // Register new hotkey
        let hotKey = HotKey(identifier: identifier, keyCombo: keyCombo, target: self, action: #selector(HotKeyService.popupSnippetFolder(_:)))
        hotKey.register()
        // Save key combos
        var keyCombos = folderKeyCombos ?? [String: KeyCombo]()
        keyCombos[identifier] = keyCombo
        folderKeyCombos = keyCombos
    }

    func unregisterSnippetHotKey(with identifier: String) {
        // Unregister
        HotKeyCenter.shared.unregisterHotKey(with: identifier)
        // Save key combos
        var keyCombos = folderKeyCombos ?? [String: KeyCombo]()
        keyCombos.removeValue(forKey: identifier)
        folderKeyCombos = keyCombos
    }

    @objc func popupSnippetFolder(_ object: AnyObject) {
        guard let hotKey = object as? HotKey else { return }
        guard let folder = AppEnvironment.current.dataService.folders.first(where: { $0.identifier == hotKey.identifier }) else {
            // When already deleted folder, remove keycombos
            unregisterSnippetHotKey(with: hotKey.identifier)
            return
        }
        if !folder.enable { return }

        AppEnvironment.current.menuManager.popUpSnippetFolder(folder)
    }

    fileprivate func setupSnippetHotKeys() {
        folderKeyCombos?.forEach {
            let hotKey = HotKey(identifier: $0, keyCombo: $1, target: self, action: #selector(HotKeyService.popupSnippetFolder(_:)))
            hotKey.register()
        }
    }
}
