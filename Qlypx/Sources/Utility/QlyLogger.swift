import Foundation
import os.log
import Cocoa

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

// MARK: - Diagnostic Service
final class DiagnosticService {

    // MARK: - Properties
    static let shared = DiagnosticService()
    private let reportURL = URL(string: "https://api.qlypx-app.com/report")!
    
    private var diagnosticFolder: String {
        return CPYUtilities.applicationSupportFolder() + "/Diagnostic"
    }
    
    private var crashLogPath: String {
        return diagnosticFolder + "/crash.log"
    }

    // MARK: - Initialization
    func setup() {
        guard AppEnvironment.current.defaults.bool(forKey: Constants.UserDefaults.collectCrashReport) else { return }
        
        setupCrashHandler()
        checkForPendingReports()
    }

    // MARK: - Crash Handling
    private func setupCrashHandler() {
        NSSetUncaughtExceptionHandler { exception in
            let diagnosticService = DiagnosticService.shared
            let report = """
            Crash Report
            Date: \(Date())
            App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
            macOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)
            
            Exception Name: \(exception.name.rawValue)
            Reason: \(exception.reason ?? "No reason")
            Stack Trace:
            \(exception.callStackSymbols.joined(separator: "\n"))
            """
            
            diagnosticService.saveCrashLog(report)
        }
    }

    fileprivate func saveCrashLog(_ report: String) {
        if CPYUtilities.prepareSaveToPath(diagnosticFolder) {
            try? report.write(toFile: crashLogPath, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Report Submission
    private func checkForPendingReports() {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: crashLogPath) else { return }
        
        do {
            let report = try String(contentsOfFile: crashLogPath, encoding: .utf8)
            sendReport(report) { [weak self] success in
                if success {
                    try? fileManager.removeItem(atPath: self?.crashLogPath ?? "")
                    QlyLogger.info("Crash report submitted successfully", log: .app)
                }
            }
        } catch {
            QlyLogger.error("Failed to read pending crash report: \(error)", log: .app)
        }
    }

    func sendReport(_ content: String, completion: ((Bool) -> Void)? = nil) {
        var request = URLRequest(url: reportURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "bundleId": Bundle.main.bundleIdentifier ?? "com.qlypx.app",
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "os": "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "content": content,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion?(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                QlyLogger.error("Failed to send diagnostic report: \(error)", log: .app)
                completion?(false)
                return
            }
            
            let success = (response as? HTTPURLResponse)?.statusCode == 200
            completion?(success)
        }
        task.resume()
    }
}
