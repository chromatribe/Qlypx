import Cocoa
import Sauce

final class PasteService {

    // MARK: - Properties
    fileprivate let lock = NSRecursiveLock(name: "com.qlypx.app.Pastable")
}

// MARK: - Copy
extension PasteService {
    func copyToPasteboard(with clip: CPYClip) {
        lock.lock(); defer { lock.unlock() }

        let data: CPYClipData
        do {
            let fileData = try Data(contentsOf: URL(fileURLWithPath: clip.dataPath))
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: fileData)
            unarchiver.requiresSecureCoding = false
            guard let decodedData = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? CPYClipData else { return }
            data = decodedData
        } catch {
            QlyLogger.error("Failed to unarchive clip data for copy from \(clip.dataPath): \(error)", log: .clip)
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // 1. If we have an image, use writeObjects for the best compatibility
        if let image = data.image {
            pasteboard.writeObjects([image])
        }

        // 2. Set other types as well
        let types = data.types
        types.forEach { type in
            switch type {
            case .deprecatedString:
                pasteboard.setString(data.stringValue, forType: .deprecatedString)
            case .deprecatedRTFD:
                if let rtfData = data.RTFData {
                    pasteboard.setData(rtfData, forType: .deprecatedRTFD)
                }
            case .deprecatedRTF:
                if let rtfData = data.RTFData {
                    pasteboard.setData(rtfData, forType: .deprecatedRTF)
                }
            case .deprecatedPDF:
                if let pdfData = data.PDF, let pdfRep = NSPDFImageRep(data: pdfData) {
                    pasteboard.setData(pdfRep.pdfRepresentation, forType: .deprecatedPDF)
                }
            case .deprecatedFilenames:
                pasteboard.setPropertyList(data.fileNames, forType: .deprecatedFilenames)
            case .deprecatedURL:
                pasteboard.setPropertyList(data.URLs, forType: .deprecatedURL)
            default:
                break
            }
        }
    }

    func copyToPasteboard(with string: String) {
        lock.lock(); defer { lock.unlock() }

        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.deprecatedString], owner: nil)
        pasteboard.setString(string, forType: .deprecatedString)
    }

    func paste(with clip: CPYClip) {
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
