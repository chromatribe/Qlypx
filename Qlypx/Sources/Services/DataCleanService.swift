//
//  DataCleanService.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2016/11/20.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation
import Combine

final class DataCleanService {

    // MARK: - Properties
    fileprivate var cancellables = Set<AnyCancellable>()

    // MARK: - Monitoring
    func startMonitoring() {
        cancellables = []
        // Clean datas every 30 minutes
        Timer.publish(every: 60 * 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanDatas()
            }
            .store(in: &cancellables)
    }

    // MARK: - Delete Data
    func cleanDatas() {
        let dataService = AppEnvironment.current.dataService
        let maxHistorySize = AppEnvironment.current.defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)
        
        if dataService.clips.count > maxHistorySize {
            let overflowingClips = dataService.clips.suffix(from: maxHistorySize)
            overflowingClips
                .filter { !$0.thumbnailPath.isEmpty }
                .map { $0.thumbnailPath }
                .forEach { ImageCacheService.shared.removeImage(forKey: $0) }
            
            // Delete from DataService
            for clip in overflowingClips {
                dataService.deleteClip(with: clip.dataHash)
            }
        }
        cleanFiles()
    }

    private func cleanFiles() {
        let fileManager = FileManager.default
        guard let paths = try? fileManager.contentsOfDirectory(atPath: CPYUtilities.applicationSupportFolder()) else { return }

        let dataService = AppEnvironment.current.dataService
        let allClipPaths = Set(dataService.clips.compactMap { $0.dataPath.components(separatedBy: "/").last })

        // Delete diff datas
        DispatchQueue.main.async {
            paths.filter { $0.hasSuffix(".data") && !allClipPaths.contains($0) }
                .map { CPYUtilities.applicationSupportFolder() + "/" + "\($0)" }
                .forEach { CPYUtilities.deleteData(at: $0) }
        }
    }
}
