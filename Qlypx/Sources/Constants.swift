//
//  Constants.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2016/04/17.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation

struct Constants {

    struct Application {
        #if DEBUG
            static let name = "QlypxDEBUG"
        #else
            static let name = "Qlypx"
        #endif
    }

    struct Menu {
        static let clip = "ClipMenu"
        static let history = "HistoryMenu"
        static let snippet = "SnippetsMenu"
    }

    struct Common {
        static let index = "index"
        static let title = "title"
        static let snippets = "snippets"
        static let content = "content"
        static let selector = "selector"
        static let draggedDataType = "public.data"
    }

    struct UserDefaults {
        static let hotKeys = "kQLYPrefHotKeysKey"
        static let menuIconSize = "kQLYPrefMenuIconSizeKey"
        static let maxHistorySize = "kQLYPrefMaxHistorySizeKey"
        static let storeTypes = "kQLYPrefStoreTypesKey"
        static let inputPasteCommand = "kQLYPrefInputPasteCommandKey"
        static let showIconInTheMenu = "kQLYPrefShowIconInTheMenuKey"
        static let numberOfItemsPlaceInline = "kQLYPrefNumberOfItemsPlaceInlineKey"
        static let numberOfItemsPlaceInsideFolder  = "kQLYPrefNumberOfItemsPlaceInsideFolderKey"
        static let maxMenuItemTitleLength = "kQLYPrefMaxMenuItemTitleLengthKey"
        static let menuItemsTitleStartWithZero = "kQLYPrefMenuItemsTitleStartWithZeroKey"
        static let reorderClipsAfterPasting = "kQLYPrefReorderClipsAfterPasting"
        static let addClearHistoryMenuItem = "kQLYPrefAddClearHistoryMenuItemKey"
        static let showAlertBeforeClearHistory = "kQLYPrefShowAlertBeforeClearHistoryKey"
        static let menuItemsAreMarkedWithNumbers = "menuItemsAreMarkedWithNumbers"
        static let showToolTipOnMenuItem = "showToolTipOnMenuItem"
        static let showImageInTheMenu = "showImageInTheMenu"
        static let addNumericKeyEquivalents = "addNumericKeyEquivalents"
        static let maxLengthOfToolTip = "maxLengthOfToolTipKey"
        static let loginItem = "loginItem"
        static let suppressAlertForLoginItem = "suppressAlertForLoginItem"
        static let showStatusItem = "kQLYPrefShowStatusItemKey"
        static let thumbnailWidth = "thumbnailWidth"
        static let thumbnailHeight = "thumbnailHeight"
        static let overwriteSameHistory = "kQLYPrefOverwriteSameHistroy"
        static let copySameHistory = "kQLYPrefCopySameHistroy"
        static let suppressAlertForDeleteSnippet = "kQLYSuppressAlertForDeleteSnippet"
        static let excludeApplications = "kQLYExcludeApplications"
        static let collectCrashReport = "kQLYCollectCrashReport"
        static let showColorPreviewInTheMenu = "kQLYPrefShowColorPreviewInTheMenu"
        static let monitoringSpeed = "kQLYPrefMonitoringSpeedKey"
        static let language = "kQLYPrefLanguageKey"
    }


    struct Update {
        static let enableAutomaticCheck = "kQLYEnableAutomaticCheckKey"
        static let checkInterval = "kQLYUpdateCheckIntervalKey"
    }

    struct Notification {
        static let closeSnippetEditor = "kQLYSnippetEditorWillCloseNotification"
    }

    struct Xml {
        static let fileType = "xml"
        static let type = "type"
        static let rootElement = "folders"
        static let folderElement = "folder"
        static let snippetElement = "snippet"
        static let titleElement = "title"
        static let snippetsElement = "snippets"
        static let contentElement = "content"
    }

    struct HotKey {
        static let mainKeyCombo = "kQLYHotKeyMainKeyCombo"
        static let historyKeyCombo = "kQLYHotKeyHistoryKeyCombo"
        static let snippetKeyCombo = "kQLYHotKeySnippetKeyCombo"
        static let migrateNewKeyCombo = "kQLYMigrateNewKeyCombo"
        static let folderKeyCombos = "kQLYFolderKeyCombos"
        static let clearHistoryKeyCombo = "kQLYClearHistoryKeyCombo"
    }

}
