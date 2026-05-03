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

    static func warn(_ message: String, log: OSLog = .app, file: String = #file, line: Int = #line) {
        os_log("%{public}@", log: log, type: .default, "⚠️ \(message)")
        #if !DEBUG
        SlackNotificationService.shared.notify(message: message, level: "WARNING", file: file, line: line)
        #endif
    }

    static func error(_ message: String, log: OSLog = .app, file: String = #file, line: Int = #line) {
        os_log("%{public}@", log: log, type: .error, "❌ \(message)")
        #if !DEBUG
        SlackNotificationService.shared.notify(message: message, level: "ERROR", file: file, line: line)
        #endif
    }
}

// MARK: - Slack Notification Service
final class SlackNotificationService {
    static let shared = SlackNotificationService()
    
    // Slack Webhook URL
    private let webhookURL = URL(string: "https://hooks.slack.com/services/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")
    
    func notify(message: String, level: String, file: String, line: Int) {
        guard let url = webhookURL else { return }
        
        let fileName = (file as NSString).lastPathComponent
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let deviceModel = getDeviceModel()
        
        let slackMessage = """
        *[\(level)] Qlypx Error Report*
        > *Message:* \(message)
        > *Location:* \(fileName):\(line)
        > *App Version:* \(appVersion)
        > *OS Version:* \(osVersion)
        > *Device:* \(deviceModel)
        """
        
        let payload: [String: Any] = ["text": slackMessage]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            return
        }
        
        URLSession.shared.dataTask(with: request).resume()
    }

    func notifyRaw(message: String) {
        guard let url = webhookURL else { return }
        let payload: [String: Any] = ["text": message]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            return
        }
        URLSession.shared.dataTask(with: request).resume()
    }
    
    private func getDeviceModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}

// MARK: - Diagnostic Service
final class DiagnosticService {
// ... (rest of the file remains the same)

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
            if success {
                #if !DEBUG
                SlackNotificationService.shared.notifyRaw(message: "*[CRASH] Qlypx Crash Report Submitted*\n```\(content)```")
                #endif
            }
            completion?(success)
        }
        task.resume()
    }
}
