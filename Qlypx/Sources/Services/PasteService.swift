import Cocoa
import Sauce

final class PasteService {

    // MARK: - Properties
    fileprivate let lock = NSRecursiveLock(name: "com.qlypx.app.Pastable")
}

// MARK: - Copy
extension PasteService {
    func copyToPasteboard(with clip: QLYClip) {
        lock.lock(); defer { lock.unlock() }

        let data: QLYClipData
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: clip.fullDataPath))
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: fileData)
            unarchiver.requiresSecureCoding = false
            guard let decodedData = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? QLYClipData else { return }
            data = decodedData
        } catch {
            QlyLogger.error("Failed to unarchive clip data for copy from \(clip.dataPath): \(error)", log: .clip)
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // 1. Handle objects (Images and File URLs)
        var objectsToWriter = [NSPasteboardWriting]()
        if let image = data.image {
            objectsToWriter.append(image)
        }
        if !data.fileURLs.isEmpty {
            data.fileURLs.forEach { objectsToWriter.append($0 as NSURL) }
        }

        if !objectsToWriter.isEmpty {
            pasteboard.writeObjects(objectsToWriter)
        }

        // 2. Set other types as well
        let types = data.types
        types.forEach { type in
            switch type {
            case NSPasteboard.PasteboardType.string, NSPasteboard.PasteboardType.legacyString:
                if pasteboard.string(forType: .string) == nil {
                    pasteboard.setString(data.stringValue, forType: .string)
                }
            case NSPasteboard.PasteboardType.rtfd, NSPasteboard.PasteboardType.legacyRTFD:
                if let rtfData = data.RTFData, pasteboard.data(forType: .rtfd) == nil {
                    pasteboard.setData(rtfData, forType: .rtfd)
                }
            case NSPasteboard.PasteboardType.rtf, NSPasteboard.PasteboardType.legacyRTF:
                if let rtfData = data.RTFData, pasteboard.data(forType: .rtf) == nil {
                    pasteboard.setData(rtfData, forType: .rtf)
                }
            case NSPasteboard.PasteboardType.pdf, NSPasteboard.PasteboardType.legacyPDF:
                if let pdfData = data.PDF, pasteboard.data(forType: .pdf) == nil {
                    // Directly write PDF data for best compatibility
                    pasteboard.setData(pdfData, forType: .pdf)
                }
            case NSPasteboard.PasteboardType.legacyFilenames:
                if pasteboard.propertyList(forType: .legacyFilenames) == nil {
                    pasteboard.setPropertyList(data.fileNames, forType: .legacyFilenames)
                }
            case NSPasteboard.PasteboardType.URL, NSPasteboard.PasteboardType.legacyURL:
                if pasteboard.propertyList(forType: .URL) == nil {
                    pasteboard.setPropertyList(data.URLs, forType: .URL)
                }
            default:
                break
            }
        }
    }

    func copyToPasteboard(with string: String) {
        lock.lock(); defer { lock.unlock() }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(string, forType: .string)
    }

    func paste(with clip: QLYClip) {
        copyToPasteboard(with: clip)
        paste()
    }
}

// MARK: - Paste
extension PasteService {
    func paste() {
        guard AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.inputPasteCommand) else { return }
        // Check Accessibility Permission
        guard AppEnvironment.current.accessibilityService.isAccessibilityEnabled(isPrompt: false) else {
            AppEnvironment.current.accessibilityService.showAccessibilityAuthenticationAlert()
            return
        }

        let vKeyCode = Sauce.shared.keyCode(for: .v)
        DispatchQueue.main.async {
            let source = CGEventSource(stateID: .combinedSessionState)
            // Disable local keyboard events while pasting
            source?.setLocalEventsFilterDuringSuppressionState([.permitLocalMouseEvents, .permitSystemDefinedEvents], state: .eventSuppressionStateSuppressionInterval)
            // Press Command + V
            let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
            keyVDown?.flags = .maskCommand
            // Release Command + V
            let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
            keyVUp?.flags = .maskCommand
            // Post Paste Command
            keyVDown?.post(tap: .cgAnnotatedSessionEventTap)
            keyVUp?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
