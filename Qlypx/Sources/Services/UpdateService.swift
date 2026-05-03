import Foundation
import Cocoa

final class UpdateService {
    
    // MARK: - Properties
    private let versionURL = URL(string: "https://raw.githubusercontent.com/qlypx/Qlypx/main/version.json")!
    private let downloadURL = URL(string: "https://chromatri.be/download")!
    
    // MARK: - Update Check
    func checkForUpdates(isManual: Bool = false) {
        let task = URLSession.shared.dataTask(with: versionURL) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                if isManual { self.showErrorAlert(error) }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                QlyLogger.debug("Update check skipped (Status code: \(code))")
                if isManual { self.showNoUpdateAlert() }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let latestVersion = json["version"] as? String {
                    
                    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
                    
                    if self.isNewer(latest: latestVersion, current: currentVersion) {
                        DispatchQueue.main.async {
                            self.showUpdateAlert(latestVersion: latestVersion)
                        }
                    } else if isManual {
                        DispatchQueue.main.async {
                            self.showNoUpdateAlert()
                        }
                    }
                }
            } catch {
                QlyLogger.error("Failed to parse version JSON: \(error)")
            }
        }
        task.resume()
    }
    
    private func isNewer(latest: String, current: String) -> Bool {
        return latest.compare(current, options: .numeric) == .orderedDescending
    }
    
    // MARK: - Alerts
    private func showUpdateAlert(latestVersion: String) {
        let alert = NSAlert()
        alert.messageText = "新しいバージョン (\(latestVersion)) が利用可能です"
        alert.informativeText = "最新の Qlypx をダウンロードして、アプリケーションを更新してください。"
        alert.addButton(withTitle: "ダウンロード")
        alert.addButton(withTitle: "後で")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(downloadURL)
        }
    }
    
    private func showNoUpdateAlert() {
        let alert = NSAlert()
        alert.messageText = "最新の状態です"
        alert.informativeText = "現在、最新バージョンの Qlypx を使用しています。"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "アップデート確認エラー"
        alert.informativeText = "アップデートの確認中にエラーが発生しました：\n\(error.localizedDescription)"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
