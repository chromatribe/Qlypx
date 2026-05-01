import Foundation
import os.log

extension OSLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.qlypx.app"

    static let app = OSLog(subsystem: subsystem, category: "App")
    static let clip = OSLog(subsystem: subsystem, category: "Clip")
    static let hotkey = OSLog(subsystem: subsystem, category: "HotKey")
    static let menu = OSLog(subsystem: subsystem, category: "Menu")
    static let cache = OSLog(subsystem: subsystem, category: "Cache")
    static let environment = OSLog(subsystem: subsystem, category: "Environment")
}

final class QlyLogger {
    static func debug(_ message: String, log: OSLog = .app, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        os_log("%{public}@", log: log, type: .debug, logMessage)
        #endif
    }

    static func info(_ message: String, log: OSLog = .app) {
        os_log("%{public}@", log: log, type: .info, message)
    }

    static func warn(_ message: String, log: OSLog = .app) {
        os_log("%{public}@", log: log, type: .default, "⚠️ \(message)")
    }

    static func error(_ message: String, log: OSLog = .app) {
        os_log("%{public}@", log: log, type: .error, "❌ \(message)")
    }
}
