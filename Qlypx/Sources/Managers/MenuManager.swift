//
//  MenuManager.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2016/03/08.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa
import Combine
import Magnet

final class MenuManager: NSObject {

    // MARK: - Properties
    // Menus
    fileprivate var clipMenu: NSMenu?
    fileprivate var historyMenu: NSMenu?
    fileprivate var snippetMenu: NSMenu?
    // StatusMenu
    fileprivate var statusItem: NSStatusItem?
    fileprivate var currentStatusType: StatusType?
    // Icon Cache
    fileprivate let folderIcon = Asset.iconFolder.image
    fileprivate let snippetIcon = Asset.iconText.image
    // Other
    fileprivate var cancellables = Set<AnyCancellable>()
    fileprivate let notificationCenter = NotificationCenter.default
    fileprivate let kMaxKeyEquivalents = 10
    fileprivate let shortenSymbol = "..."

    // MARK: - Enum Values
    enum StatusType: Int {
        case none = 0
        case clipboard = 1
        case arrow = 2
        case copy = 3
    }

    // MARK: - Initialize
    override init() {
        super.init()
        folderIcon.isTemplate = true
        folderIcon.size = NSSize(width: 15, height: 13)
        snippetIcon.isTemplate = true
        snippetIcon.size = NSSize(width: 12, height: 13)
    }

    func setup() {
        QlyLogger.debug("Setting up MenuManager", log: .menu)
        createClipMenu()
        bind()
    }

}

// MARK: - Popup Menu
extension MenuManager {
    func popUpMenu(_ type: MenuType) {
        QlyLogger.debug("Popping up menu: \(type.rawValue)", log: .menu)
        let menu: NSMenu?
        switch type {
        case .main:
            menu = clipMenu
        case .history:
            menu = historyMenu
        case .snippet:
            menu = snippetMenu
        }
        menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    func popUpSnippetFolder(_ folder: CPYFolder) {
        let folderMenu = NSMenu(title: folder.title)
        // Folder title
        let labelItem = NSMenuItem(title: folder.title, action: nil)
        labelItem.isEnabled = false
        folderMenu.addItem(labelItem)
        // Snippets
        var index = 0
        folder.snippets
            .sorted(by: { $0.index < $1.index })
            .filter { $0.enable }
            .forEach { snippet in
                let subMenuItem = makeSnippetMenuItem(snippet, relativeIndex: index)
                folderMenu.addItem(subMenuItem)
                index += 1
            }
        folderMenu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

// MARK: - Binding
private extension MenuManager {
    func bind() {
        cancellables = []
        // DataService Notification
        notificationCenter.publisher(for: .clipsUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.createClipMenu()
            }
            .store(in: &cancellables)

        notificationCenter.publisher(for: .snippetsUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.createClipMenu()
            }
            .store(in: &cancellables)

        // Menu icon
        AppEnvironment.current.defaults.qly_observe(Int.self, Constants.UserDefaults.showStatusItem)
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (key: Int) in
                self?.changeStatusItem(StatusType(rawValue: key) ?? .clipboard)
            }
            .store(in: &cancellables)

        // Sort clips
        AppEnvironment.current.defaults.qly_observe(Bool.self, Constants.UserDefaults.reorderClipsAfterPasting)
            .compactMap { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_: Bool) in
                self?.createClipMenu()
            }
            .store(in: &cancellables)

        // Edit snippets
        notificationCenter.publisher(for: Notification.Name(rawValue: Constants.Notification.closeSnippetEditor))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_: Notification) in
                self?.createClipMenu()
            }
            .store(in: &cancellables)

        // Various menu settings
        [Constants.UserDefaults.maxHistorySize,
         Constants.UserDefaults.numberOfItemsPlaceInline,
         Constants.UserDefaults.numberOfItemsPlaceInsideFolder,
         Constants.UserDefaults.maxMenuItemTitleLength,
         Constants.UserDefaults.menuItemsTitleStartWithZero,
         Constants.UserDefaults.menuItemsAreMarkedWithNumbers,
         Constants.UserDefaults.showToolTipOnMenuItem,
         Constants.UserDefaults.showImageInTheMenu,
         Constants.UserDefaults.showColorPreviewInTheMenu,
         Constants.UserDefaults.addNumericKeyEquivalents,
         Constants.UserDefaults.maxLengthOfToolTip,
         Constants.UserDefaults.showIconInTheMenu].forEach { key in
            AppEnvironment.current.defaults.qly_observe(Any.self, key)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.createClipMenu()
                }
                .store(in: &cancellables)
        }
    }
}

// MARK: - Menus
private extension MenuManager {
     func createClipMenu() {
        clipMenu = NSMenu(title: Constants.Application.name)
        historyMenu = NSMenu(title: Constants.Menu.history)
        snippetMenu = NSMenu(title: Constants.Menu.snippet)

        addHistoryItems(clipMenu!)
        addHistoryItems(historyMenu!)

        addSnippetItems(clipMenu!, separateMenu: true)
        addSnippetItems(snippetMenu!, separateMenu: false)

        clipMenu?.addItem(NSMenuItem.separator())

        if AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.addClearHistoryMenuItem) {
            clipMenu?.addItem(NSMenuItem(title: L10n.clearHistory, action: #selector(AppDelegate.clearAllHistory)))
        }

        clipMenu?.addItem(NSMenuItem(title: L10n.editSnippets, action: #selector(AppDelegate.showSnippetEditorWindow)))
        clipMenu?.addItem(NSMenuItem(title: L10n.preferences, action: #selector(AppDelegate.showPreferenceWindow)))
        clipMenu?.addItem(NSMenuItem.separator())
        clipMenu?.addItem(NSMenuItem(title: L10n.quitQlypx, action: #selector(AppDelegate.terminate)))

        statusItem?.menu = clipMenu
    }


    func makeSubmenuItem(_ count: Int, start: Int, end: Int, numberOfItems: Int) -> NSMenuItem {
        var count = count
        if start == 0 {
            count -= 1
        }
        var lastNumber = count + numberOfItems
        if end < lastNumber {
            lastNumber = end
        }
        let menuItemTitle = "\(count + 1) - \(lastNumber)"
        return makeSubmenuItem(menuItemTitle)
    }

    func makeSubmenuItem(_ title: String) -> NSMenuItem {
        let subMenu = NSMenu(title: "")
        let subMenuItem = NSMenuItem(title: title, action: nil)
        subMenuItem.submenu = subMenu
        subMenuItem.image = (AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showIconInTheMenu)) ? folderIcon : nil
        return subMenuItem
    }

    func shortcut(for relativeIndex: Int) -> String {
        let isStartFromZero = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.menuItemsTitleStartWithZero)
        
        if isStartFromZero {
            // 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, a, b, c...
            if relativeIndex < 10 {
                return "\(relativeIndex)"
            } else {
                let alphaIndex = relativeIndex - 10
                if alphaIndex < 26 {
                    return String(Character(UnicodeScalar(UInt8(ascii: "a") + UInt8(alphaIndex))))
                }
            }
        } else {
            // 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, a, b, c...
            if relativeIndex < 9 {
                return "\(relativeIndex + 1)"
            } else if relativeIndex == 9 {
                return "0"
            } else {
                let alphaIndex = relativeIndex - 10
                if alphaIndex < 26 {
                    return String(Character(UnicodeScalar(UInt8(ascii: "a") + UInt8(alphaIndex))))
                }
            }
        }
        return ""
    }

    func trimTitle(_ title: String?) -> String {
        if title == nil { return "" }
        let theString = title!.trimmingCharacters(in: .whitespacesAndNewlines) as NSString

        let aRange = NSRange(location: 0, length: 0)
        var lineStart = 0, lineEnd = 0, contentsEnd = 0
        theString.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: aRange)

        var titleString = (lineEnd == theString.length) ? theString as String : theString.substring(to: contentsEnd)

        var maxMenuItemTitleLength = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxMenuItemTitleLength)
        if maxMenuItemTitleLength < shortenSymbol.count {
            maxMenuItemTitleLength = shortenSymbol.count
        }

        if titleString.utf16.count > maxMenuItemTitleLength {
            titleString = (titleString as NSString).substring(to: maxMenuItemTitleLength - shortenSymbol.count) + shortenSymbol
        }

        return titleString as String
    }
}

// MARK: - Clips
private extension MenuManager {
    func addHistoryItems(_ menu: NSMenu) {
        let placeInLine = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.numberOfItemsPlaceInline)
        let placeInsideFolder = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.numberOfItemsPlaceInsideFolder)
        let maxHistory = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)

        // History title
        let labelItem = NSMenuItem(title: L10n.history, action: nil)
        labelItem.isEnabled = false
        menu.addItem(labelItem)

        // History
        let firstIndex = firstIndexOfMenuItems()
        var relativeIndex = 0
        var subMenuCount = placeInLine
        var subMenuIndex = 1 + placeInLine

        let ascending = !AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.reorderClipsAfterPasting)
        let clips = AppEnvironment.current.dataService.clips.sorted(by: { 
            if ascending {
                return $0.updateTime < $1.updateTime
            } else {
                return $0.updateTime > $1.updateTime
            }
        })
        let currentSize = clips.count
        var i = 0
        for clip in clips {
            if placeInLine < 1 || placeInLine - 1 < i {
                // Folder
                if i == subMenuCount {
                    let subMenuItem = makeSubmenuItem(subMenuCount, start: firstIndex, end: currentSize, numberOfItems: placeInsideFolder)
                    menu.addItem(subMenuItem)
                    relativeIndex = 0
                }

                // Clip
                if let subMenu = menu.item(at: subMenuIndex)?.submenu {
                    let menuItem = makeClipMenuItem(clip, relativeIndex: relativeIndex)
                    subMenu.addItem(menuItem)
                    relativeIndex += 1
                }
            } else {
                // Clip
                let menuItem = makeClipMenuItem(clip, relativeIndex: relativeIndex)
                menu.addItem(menuItem)
                relativeIndex += 1
            }

            i += 1
            if i == subMenuCount + placeInsideFolder {
                subMenuCount += placeInsideFolder
                subMenuIndex += 1
            }

            if maxHistory <= i { break }
        }
    }

    func makeClipMenuItem(_ clip: CPYClip, relativeIndex: Int) -> NSMenuItem {
        let isMarkWithNumber = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.menuItemsAreMarkedWithNumbers)
        let isShowToolTip = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showToolTipOnMenuItem)
        let isShowImage = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showImageInTheMenu)
        let isShowColorCode = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showColorPreviewInTheMenu)
        let addNumbericKeyEquivalents = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.addNumericKeyEquivalents)

        let shortcut = (addNumbericKeyEquivalents) ? self.shortcut(for: relativeIndex) : ""

        let primaryPboardType = NSPasteboard.PasteboardType(rawValue: clip.primaryType)
        let clipString = clip.title
        let title = trimTitle(clipString)
        
        let displayTitle: String
        if primaryPboardType.isImage {
            displayTitle = L10n.image
        } else if primaryPboardType.isPDF {
            displayTitle = L10n.pdf
        } else if primaryPboardType.isFileURL && title.isEmpty {
            displayTitle = L10n.filenames
        } else {
            displayTitle = title
        }

        let menuItem = NSMenuItem(title: "", action: #selector(AppDelegate.selectClipMenuItem(_:)), keyEquivalent: shortcut)
        menuItem.target = NSApp.delegate
        menuItem.representedObject = clip.dataHash

        if isShowToolTip {
            let maxLengthOfToolTip = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxLengthOfToolTip)
            let toIndex = (clipString.count < maxLengthOfToolTip) ? clipString.count : maxLengthOfToolTip
            menuItem.toolTip = (clipString as NSString).substring(to: toIndex)
        }

        let updateAttributedTitle: (NSImage?) -> Void = { [weak menuItem] thumbImage in
            guard let menuItem = menuItem else { return }
            let attrTitle = NSMutableAttributedString()
            
            // Number
            if isMarkWithNumber {
                let label = (shortcut.isEmpty) ? "\(relativeIndex + 1)" : shortcut
                attrTitle.append(NSAttributedString(string: "\(label). ", attributes: [.font: NSFont.menuFont(ofSize: 0)]))
            }
            
            // Image (Thumbnail)
            if let img = thumbImage {
                let attachment = NSTextAttachment()
                attachment.image = img
                // Align image vertically with text
                let font = NSFont.menuFont(ofSize: 0)
                attachment.bounds = CGRect(x: 0, y: font.descender, width: img.size.width, height: img.size.height)
                
                attrTitle.append(NSAttributedString(attachment: attachment))
                attrTitle.append(NSAttributedString(string: " "))
            }
            
            // Title
            attrTitle.append(NSAttributedString(string: displayTitle, attributes: [.font: NSFont.menuFont(ofSize: 0)]))
            menuItem.attributedTitle = attrTitle
        }

        // Initial title without image
        updateAttributedTitle(nil)

        if !clip.thumbnailPath.isEmpty && ((!clip.isColorCode && isShowImage) || (clip.isColorCode && isShowColorCode)) {
            ImageCacheService.shared.image(forKey: clip.thumbnailPath) { _, image in
                updateAttributedTitle(image)
            }
        }

        return menuItem
    }
}

// MARK: - Snippets
private extension MenuManager {
    func addSnippetItems(_ menu: NSMenu, separateMenu: Bool) {
        let folders = AppEnvironment.current.dataService.folders.sorted(by: { $0.index < $1.index })
        guard !folders.isEmpty else { return }
        if separateMenu {
            menu.addItem(NSMenuItem.separator())
        }

        // Snippet title
        let labelItem = NSMenuItem(title: L10n.snippet, action: nil)
        labelItem.isEnabled = false
        menu.addItem(labelItem)

        var subMenuIndex = menu.numberOfItems - 1

        folders
            .filter { $0.enable }
            .forEach { folder in
                let folderTitle = folder.title
                let subMenuItem = makeSubmenuItem(folderTitle)
                menu.addItem(subMenuItem)
                subMenuIndex += 1

                var relativeIndex = 0
                folder.snippets
                    .sorted(by: { $0.index < $1.index })
                    .filter { $0.enable }
                    .forEach { snippet in
                        let subMenuItem = makeSnippetMenuItem(snippet, relativeIndex: relativeIndex)
                        if let subMenu = menu.item(at: subMenuIndex)?.submenu {
                            subMenu.addItem(subMenuItem)
                            relativeIndex += 1
                        }
                    }
            }
    }

    func makeSnippetMenuItem(_ snippet: CPYSnippet, relativeIndex: Int) -> NSMenuItem {
        let isMarkWithNumber = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.menuItemsAreMarkedWithNumbers)
        let isShowIcon = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.showIconInTheMenu)
        let addNumbericKeyEquivalents = AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.addNumericKeyEquivalents)

        let shortcut = (addNumbericKeyEquivalents) ? self.shortcut(for: relativeIndex) : ""
        let title = trimTitle(snippet.title)
        let menuItem = NSMenuItem(title: "", action: #selector(AppDelegate.selectSnippetMenuItem(_:)), keyEquivalent: shortcut)
        menuItem.target = NSApp.delegate
        menuItem.representedObject = snippet.identifier
        menuItem.toolTip = snippet.content

        let attrTitle = NSMutableAttributedString()
        
        // Number
        if isMarkWithNumber {
            let label = (shortcut.isEmpty) ? "\(relativeIndex + 1)" : shortcut
            attrTitle.append(NSAttributedString(string: "\(label). ", attributes: [.font: NSFont.menuFont(ofSize: 0)]))
        }
        
        // Icon
        if isShowIcon {
            let attachment = NSTextAttachment()
            attachment.image = snippetIcon
            let font = NSFont.menuFont(ofSize: 0)
            attachment.bounds = CGRect(x: 0, y: font.descender, width: snippetIcon.size.width, height: snippetIcon.size.height)
            
            attrTitle.append(NSAttributedString(attachment: attachment))
            attrTitle.append(NSAttributedString(string: " "))
        }
        
        // Title
        attrTitle.append(NSAttributedString(string: title, attributes: [.font: NSFont.menuFont(ofSize: 0)]))
        menuItem.attributedTitle = attrTitle

        return menuItem
    }
}

// MARK: - Status Item
private extension MenuManager {
    func changeStatusItem(_ type: StatusType) {
        if type == currentStatusType { return }
        currentStatusType = type
        
        removeStatusItem()
        if type == .none { return }

        let image: NSImage?
        switch type {
        case .clipboard:
            image = Asset.statusbarMenuBlack.image
        case .arrow:
            image = Asset.statusbarMenuWhite.image
        case .copy:
            image = Asset.statusbarMenuCopy.image
        case .none: return
        }
        image?.isTemplate = (type != .copy)
        image?.size = NSSize(width: 18, height: 18)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = image
        statusItem?.button?.toolTip = "\(Constants.Application.name)\(Bundle.main.appVersion ?? "")"
        statusItem?.menu = clipMenu
    }

    func removeStatusItem() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        currentStatusType = nil
    }
}

// MARK: - Settings
private extension MenuManager {
    func firstIndexOfMenuItems() -> NSInteger {
        return AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.menuItemsTitleStartWithZero) ? 0 : 1
    }
}
