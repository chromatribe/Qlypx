//
//  CPYPreferencesWindowController.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2016/02/25.
import Cocoa
import SwiftUI
import ServiceManagement
import KeyHolder
import Magnet
import UniformTypeIdentifiers

// MARK: - Constants
enum PreferenceLayout {
    static let minWidth: CGFloat = 520
    static let minHeight: CGFloat = 550
    static let horizontalPadding: CGFloat = 52
    static let bottomPadding: CGFloat = 52
    static let topPadding: CGFloat = 48
}

final class CPYPreferencesWindowController: NSWindowController {

    // MARK: - Properties
    static let sharedController = CPYPreferencesWindowController(windowNibName: "CPYPreferencesWindowController")
    
    private let viewControllers: [NSViewController] = [
        NSHostingController(rootView: GeneralSettingsView()),
        NSHostingController(rootView: MenuSettingsView()),
        NSHostingController(rootView: TypeSettingsView()),
        NSHostingController(rootView: ExcludeAppSettingsView()),
        NSHostingController(rootView: ShortcutsSettingsView())
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
            switch self {
            case .general: return L10n.general
            case .menu: return L10n.menu
            case .type: return L10n.type
            case .exclude: return L10n.exclude
            case .shortcuts: return L10n.shortcuts
            }
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

        // リサイズを可能にし、最小サイズを設定
        self.window?.styleMask.insert(.resizable)
        self.window?.minSize = NSSize(width: PreferenceLayout.minWidth, height: PreferenceLayout.minHeight)
        self.window?.setContentSize(NSSize(width: PreferenceLayout.minWidth, height: PreferenceLayout.minHeight))

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

// MARK: - Settings Store
final class SettingsStore: ObservableObject {
    @AppStorage(Constants.UserDefaults.maxHistorySize) var maxHistorySize: Int = 50
    @AppStorage(Constants.UserDefaults.reorderClipsAfterPasting) var reorderClipsAfterPasting: Int = 1
    @AppStorage(Constants.UserDefaults.showStatusItem) var showStatusItem: Int = 1
    @AppStorage(Constants.UserDefaults.loginItem) var loginItem: Bool = false
    @AppStorage(Constants.UserDefaults.collectCrashReport) var collectCrashReport: Bool = true
    @AppStorage(Constants.UserDefaults.monitoringSpeed) var monitoringSpeed: Double = 0.75
    @AppStorage(Constants.UserDefaults.language) var language: String = "System"
    
    // Menu settings
    @AppStorage(Constants.UserDefaults.numberOfItemsPlaceInline) var numberOfItemsPlaceInline: Int = 10
    @AppStorage(Constants.UserDefaults.numberOfItemsPlaceInsideFolder) var numberOfItemsPlaceInsideFolder: Int = 10
    @AppStorage(Constants.UserDefaults.maxMenuItemTitleLength) var maxMenuItemTitleLength: Int = 50
    @AppStorage(Constants.UserDefaults.menuItemsAreMarkedWithNumbers) var menuItemsAreMarkedWithNumbers: Bool = true
    @AppStorage(Constants.UserDefaults.showIconInTheMenu) var showIconInTheMenu: Bool = true
    @AppStorage(Constants.UserDefaults.showToolTipOnMenuItem) var showToolTipOnMenuItem: Bool = true
    @AppStorage(Constants.UserDefaults.maxLengthOfToolTip) var maxLengthOfToolTip: Int = 100
    @AppStorage(Constants.UserDefaults.showColorPreviewInTheMenu) var showColorPreview: Bool = true
    @AppStorage(Constants.UserDefaults.showImageInTheMenu) var showImageInTheMenu: Bool = true
    @AppStorage(Constants.UserDefaults.thumbnailWidth) var thumbnailWidth: Int = 200
    @AppStorage(Constants.UserDefaults.thumbnailHeight) var thumbnailHeight: Int = 160

    // Type settings
    @Published var storeTypes: [String: Bool] = [:]
    
    // Exclude settings
    @Published var excludedApps: [CPYAppInfo] = []
    
    // Hotkeys
    @Published var mainKeyCombo: KeyCombo?
    @Published var historyKeyCombo: KeyCombo?
    @Published var snippetKeyCombo: KeyCombo?
    @Published var clearHistoryKeyCombo: KeyCombo?

    init() {
        // Initialize Type settings
        if let dict = AppEnvironment.current.defaults.object(forKey: Constants.UserDefaults.storeTypes) as? [String: Bool] {
            self.storeTypes = dict
        } else {
            self.storeTypes = ["String": true, "RTF": true, "RTFD": true, "PDF": true, "Filenames": true, "URL": true, "TIFF": true]
        }
        
        // Initialize Exclude settings
        self.excludedApps = AppEnvironment.current.excludeAppService.applications
        
        // Initialize Hotkeys
        self.mainKeyCombo = AppEnvironment.current.hotKeyService.mainKeyCombo
        self.historyKeyCombo = AppEnvironment.current.hotKeyService.historyKeyCombo
        self.snippetKeyCombo = AppEnvironment.current.hotKeyService.snippetKeyCombo
        self.clearHistoryKeyCombo = AppEnvironment.current.hotKeyService.clearHistoryKeyCombo
    }

    func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            QlyLogger.error("Failed to update login item: \(error)")
        }
    }
    
    func setStoreType(_ type: String, enabled: Bool) {
        storeTypes[type] = enabled
        AppEnvironment.current.defaults.set(storeTypes, forKey: Constants.UserDefaults.storeTypes)
        AppEnvironment.current.defaults.synchronize()
    }
    
    func addExcludedApp(info: CPYAppInfo) {
        AppEnvironment.current.excludeAppService.add(with: info)
        excludedApps = AppEnvironment.current.excludeAppService.applications
    }
    
    func deleteExcludedApp(at offsets: IndexSet) {
        offsets.forEach { index in
            AppEnvironment.current.excludeAppService.delete(with: index)
        }
        excludedApps = AppEnvironment.current.excludeAppService.applications
    }
    
    func updateHotKey(type: MenuType, keyCombo: KeyCombo?) {
        AppEnvironment.current.hotKeyService.change(with: type, keyCombo: keyCombo)
        switch type {
        case .main: mainKeyCombo = keyCombo
        case .history: historyKeyCombo = keyCombo
        case .snippet: snippetKeyCombo = keyCombo
        }
    }
    
    func updateClearHistoryHotKey(keyCombo: KeyCombo?) {
        AppEnvironment.current.hotKeyService.changeClearHistoryKeyCombo(keyCombo)
        clearHistoryKeyCombo = keyCombo
    }
}

// MARK: - Bridge Components
struct ShortcutRecordViewWrapper: NSViewRepresentable {
    let keyCombo: KeyCombo?
    let onChange: (KeyCombo?) -> Void
    
    func makeNSView(context: Context) -> RecordView {
        let recordView = RecordView(frame: .zero)
        recordView.delegate = context.coordinator
        recordView.keyCombo = keyCombo
        return recordView
    }
    
    func updateNSView(_ nsView: RecordView, context: Context) {
        nsView.keyCombo = keyCombo
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, RecordViewDelegate {
        var parent: ShortcutRecordViewWrapper
        
        init(_ parent: ShortcutRecordViewWrapper) {
            self.parent = parent
        }
        
        func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool { true }
        func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool { true }
        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            parent.onChange(keyCombo)
        }
        func recordViewDidEndRecording(_ recordView: RecordView) {}
    }
}

// MARK: - SwiftUI Views
struct GeneralSettingsView: View {
    @StateObject private var store = SettingsStore()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Clipboard History
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.history).font(.headline)
                    HStack {
                        Text(L10n.rememberHistorySize + ":")
                        Stepper("\(store.maxHistorySize)", value: $store.maxHistorySize, in: 1...1000)
                    }
                    Picker(L10n.orderAfterPasting + ":", selection: $store.reorderClipsAfterPasting) {
                        Text(L10n.none).tag(0)
                        Text(L10n.moveToTop).tag(1)
                    }
                    .pickerStyle(.radioGroup)
                }
                
                Divider()
                
                // Monitoring Speed
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.monitoringSpeed).font(.headline)
                    Picker("", selection: $store.monitoringSpeed) {
                        Text(L10n.highSpeed).tag(0.2)
                        Text(L10n.fast).tag(0.5)
                        Text(L10n.standard).tag(0.75)
                        Text(L10n.powerSaving).tag(1.0)
                    }
                    .pickerStyle(.radioGroup)
                }
                
                Divider()
                
                // Appearance
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.appearance).font(.headline)
                    Picker(L10n.statusBarIcon + ":", selection: $store.showStatusItem) {
                        Text(L10n.black).tag(1)
                        Text(L10n.white).tag(2)
                        Text(L10n.color).tag(3)
                        Text(L10n.none).tag(0)
                    }
                }
                
                Divider()
                
                // Others
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.others).font(.headline)
                    Toggle(L10n.launchOnSystemStartup, isOn: $store.loginItem)
                        .onChange(of: store.loginItem) { newValue in
                            store.updateLoginItem(enabled: newValue)
                        }
                    Toggle(L10n.sendCrashReportsErrorLogs, isOn: $store.collectCrashReport)
                    
                    Divider().padding(.vertical, 4)
                    
                    Picker(L10n.language + ":", selection: $store.language) {
                        Text(L10n.systemLanguage).tag("System")
                        Text(L10n.japanese).tag("Japanese")
                        Text(L10n.english).tag("English")
                        Text(L10n.german).tag("German")
                        Text(L10n.italian).tag("Italian")
                        Text(L10n.simplifiedChinese).tag("Simplified Chinese")
                    }
                }
            }
            .padding(.horizontal, PreferenceLayout.horizontalPadding)
            .padding(.bottom, PreferenceLayout.bottomPadding)
            .padding(.top, PreferenceLayout.topPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: PreferenceLayout.minWidth, maxWidth: .infinity, minHeight: PreferenceLayout.minHeight, maxHeight: .infinity)
    }
}

struct MenuSettingsView: View {
    @StateObject private var store = SettingsStore()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Menu Items
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.menuItems).font(.headline)
                    HStack {
                        Text(L10n.numberOfItemsPlaceInline + ":")
                        Stepper("\(store.numberOfItemsPlaceInline)", value: $store.numberOfItemsPlaceInline, in: 1...100)
                    }
                    HStack {
                        Text(L10n.numberOfItemsInsideAFolder + ":")
                        Stepper("\(store.numberOfItemsPlaceInsideFolder)", value: $store.numberOfItemsPlaceInsideFolder, in: 1...100)
                    }
                    HStack {
                        Text(L10n.maxCharactersInTheMenu + ":")
                        Stepper("\(store.maxMenuItemTitleLength)", value: $store.maxMenuItemTitleLength, in: 1...500)
                    }
                }
                
                Divider()
                
                // Appearance
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.appearance).font(.headline)
                    Toggle(L10n.markMenuItemsWithNumbers, isOn: $store.menuItemsAreMarkedWithNumbers)
                    Toggle(L10n.displayIconsInMenuItems, isOn: $store.showIconInTheMenu)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(L10n.showToolTipOnAMenuItem, isOn: $store.showToolTipOnMenuItem)
                        if store.showToolTipOnMenuItem {
                            HStack {
                                Text(L10n.maxLengthOfToolTip + ":")
                                Stepper("\(store.maxLengthOfToolTip)", value: $store.maxLengthOfToolTip, in: 1...1000)
                            }
                            .padding(.leading, 20)
                        }
                    }
                    
                    Toggle(L10n.showColorCodePreview, isOn: $store.showColorPreview)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(L10n.showImage, isOn: $store.showImageInTheMenu)
                        if store.showImageInTheMenu {
                            HStack {
                                Text(L10n.width + ":")
                                Stepper("\(store.thumbnailWidth)", value: $store.thumbnailWidth, in: 10...500)
                                Text("px")
                                Spacer().frame(width: 20)
                                Text(L10n.height + ":")
                                Stepper("\(store.thumbnailHeight)", value: $store.thumbnailHeight, in: 10...500)
                                Text("px")
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
            }
            .padding(.horizontal, PreferenceLayout.horizontalPadding)
            .padding(.bottom, PreferenceLayout.bottomPadding)
            .padding(.top, PreferenceLayout.topPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: PreferenceLayout.minWidth, maxWidth: .infinity, minHeight: PreferenceLayout.minHeight, maxHeight: .infinity)
    }
}

struct TypeSettingsView: View {
    @StateObject private var store = SettingsStore()
    
    let types = [
        ("String", L10n.plainText),
        ("RTF", L10n.rtf),
        ("RTFD", L10n.rtfd),
        ("PDF", L10n.pdf),
        ("Filenames", L10n.filenames),
        ("URL", L10n.url),
        ("TIFF", L10n.tiffImage)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.selectClipboardTypesToStore).font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(types, id: \.0) { typeKey, label in
                            Toggle(label, isOn: Binding(
                                get: { store.storeTypes[typeKey] ?? false },
                                set: { store.setStoreType(typeKey, enabled: $0) }
                            ))
                        }
                    }
                    .padding(.leading, 4)
                }
                
                Spacer()
            }
            .padding(.horizontal, PreferenceLayout.horizontalPadding)
            .padding(.bottom, PreferenceLayout.bottomPadding)
            .padding(.top, PreferenceLayout.topPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: PreferenceLayout.minWidth, maxWidth: .infinity, minHeight: PreferenceLayout.minHeight, maxHeight: .infinity)
    }
}

struct ExcludeAppSettingsView: View {
    @StateObject private var store = SettingsStore()
    
    @State private var selectedAppId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.excludeTheseApplications).font(.headline)
                
                List(selection: $selectedAppId) {
                    ForEach(store.excludedApps, id: \.identifier) { app in
                        HStack {
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.identifier) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            } else {
                                Image(nsImage: NSWorkspace.shared.icon(for: .application))
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            Text(app.name)
                        }
                        .tag(app.identifier)
                    }
                    .onDelete(perform: store.deleteExcludedApp)
                }
                .listStyle(.inset)
                .frame(minHeight: 200)
            }
            
            HStack {
                Button(action: addApp) {
                    Image(systemName: "plus")
                    Text(L10n.add)
                }
                
                Button(action: deleteSelected) {
                    HStack {
                        Image(systemName: "minus")
                        Text(L10n.delete)
                    }
                }
                .disabled(selectedAppId == nil)
                
                Spacer()
            }
        }
        .padding(.horizontal, PreferenceLayout.horizontalPadding)
        .padding(.bottom, PreferenceLayout.bottomPadding)
        .padding(.top, PreferenceLayout.topPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func deleteSelected() {
        if let id = selectedAppId, let index = store.excludedApps.firstIndex(where: { $0.identifier == id }) {
            store.deleteExcludedApp(at: IndexSet(integer: index))
            selectedAppId = nil
        }
    }
    
    private func addApp() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.application]
        openPanel.allowsMultipleSelection = true
        openPanel.prompt = L10n.add
        
        if openPanel.runModal() == .OK {
            openPanel.urls.forEach { url in
                guard let bundle = Bundle(url: url), let info = bundle.infoDictionary else { return }
                guard let appInfo = CPYAppInfo(info: info as [String: AnyObject]) else { return }
                store.addExcludedApp(info: appInfo)
            }
        }
    }
}

struct ShortcutsSettingsView: View {
    @StateObject private var store = SettingsStore()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Menu Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.menu).font(.headline)
                    shortcutRow(label: L10n.general, keyCombo: store.mainKeyCombo) { store.updateHotKey(type: .main, keyCombo: $0) }
                    shortcutRow(label: L10n.history, keyCombo: store.historyKeyCombo) { store.updateHotKey(type: .history, keyCombo: $0) }
                    shortcutRow(label: L10n.snippet, keyCombo: store.snippetKeyCombo) { store.updateHotKey(type: .snippet, keyCombo: $0) }
                }
                
                Divider()
                
                // History Shortcuts
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.history).font(.headline)
                    shortcutRow(label: L10n.clearHistory, keyCombo: store.clearHistoryKeyCombo) { store.updateClearHistoryHotKey(keyCombo: $0) }
                }
            }
            .padding(.horizontal, PreferenceLayout.horizontalPadding)
            .padding(.bottom, PreferenceLayout.bottomPadding)
            .padding(.top, PreferenceLayout.topPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: PreferenceLayout.minWidth, maxWidth: .infinity, minHeight: PreferenceLayout.minHeight, maxHeight: .infinity)
    }
    
    private func shortcutRow(label: String, keyCombo: KeyCombo?, onChange: @escaping (KeyCombo?) -> Void) -> some View {
        HStack {
            Text(label + ":").frame(width: 120, alignment: .trailing)
            ShortcutRecordViewWrapper(keyCombo: keyCombo, onChange: onChange)
                .frame(width: 200, height: 25)
        }
    }
}
