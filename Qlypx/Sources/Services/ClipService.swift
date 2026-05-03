//
//  ClipService.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2016/11/17.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation
import Cocoa
import Combine

final class ClipService {

    // MARK: - Properties
    fileprivate var cachedChangeCount = CurrentValueSubject<Int, Never>(0)
    fileprivate var storeTypes = [String: NSNumber]()
    fileprivate let lock = NSRecursiveLock(name: "com.qlypx.app.ClipUpdatable")
    fileprivate var cancellables = Set<AnyCancellable>()

    // MARK: - Clips
    func startMonitoring() {
        cancellables = []
        // Pasteboard observe timer
        Timer.publish(every: 0.75, on: .main, in: .common)
            .autoconnect()
            .map { _ in NSPasteboard.general.changeCount }
            .filter { [weak self] changeCount in
                return changeCount != self?.cachedChangeCount.value
            }
            .sink { [weak self] changeCount in
                self?.cachedChangeCount.send(changeCount)
                self?.create()
            }
            .store(in: &cancellables)

        // Store types
        AppEnvironment.current.defaults.qly_observe([String: NSNumber].self, Constants.UserDefaults.storeTypes)
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (storeTypes: [String: NSNumber]) in
                self?.storeTypes = storeTypes
            }
            .store(in: &cancellables)
    }

    func clearAll() {
        let clips = AppEnvironment.current.dataService.clips

        // Delete saved images
        clips
            .filter { !$0.thumbnailPath.isEmpty }
            .map { $0.thumbnailPath }
            .forEach { ImageCacheService.shared.removeImage(forKey: $0) }
        
        AppEnvironment.current.dataService.clearAllClips()
        // Delete writed datas
        AppEnvironment.current.dataCleanService.cleanDatas()
    }

    func delete(with clip: CPYClip) {
        // Delete saved images
        let path = clip.thumbnailPath
        if !path.isEmpty {
            ImageCacheService.shared.removeImage(forKey: path)
        }
        AppEnvironment.current.dataService.deleteClip(with: clip.dataHash)
    }

    func incrementChangeCount() {
        cachedChangeCount.send(cachedChangeCount.value + 1)
    }

}

// MARK: - Create Clip
extension ClipService {
    fileprivate func create() {
        lock.lock(); defer { lock.unlock() }

        // Store types
        if !storeTypes.values.contains(NSNumber(value: true)) { return }
        // Pasteboard types
        let pasteboard = NSPasteboard.general
        let types = self.types(with: pasteboard)
        if types.isEmpty { return }

        // Excluded application
        guard !AppEnvironment.current.excludeAppService.frontProcessIsExcludedApplication() else { return }
        // Special applications
        guard !AppEnvironment.current.excludeAppService.copiedProcessIsExcludedApplications(pasteboard: pasteboard) else { return }

        // Create data
        let data = CPYClipData(pasteboard: pasteboard, types: types)
        save(with: data)
    }

    func create(with image: NSImage) {
        lock.lock(); defer { lock.unlock() }

        // Create only image data
        let data = CPYClipData(image: image)
        save(with: data)
    }

    fileprivate func save(with data: CPYClipData) {
        let dataService = AppEnvironment.current.dataService

        // Don't save empty string history
        if data.isOnlyStringType && data.stringValue.isEmpty { return }

        // Use data hash to ensure duplicates are handled by upsert (moving to top)
        let savedHash = data.hash

        // Saved time and path
        let unixTime = Int(Date().timeIntervalSince1970)
        let savedPath = CPYUtilities.applicationSupportFolder() + "/\(NSUUID().uuidString).data"
        
        let clip = CPYClip()
        clip.dataPath = savedPath
        clip.title = data.stringValue[0...10000]
        clip.dataHash = "\(savedHash)"
        clip.updateTime = unixTime
        clip.primaryType = data.primaryType?.rawValue ?? ""

        DispatchQueue.main.async {
            // Save thumbnail image
            if let thumbnailImage = data.thumbnailImage {
                ImageCacheService.shared.setImage(thumbnailImage, forKey: "\(unixTime)")
                clip.thumbnailPath = "\(unixTime)"
            }
            if let colorCodeImage = data.colorCodeImage {
                ImageCacheService.shared.setImage(colorCodeImage, forKey: "\(unixTime)")
                clip.thumbnailPath = "\(unixTime)"
                clip.isColorCode = true
            }
            // Save JSON and .data file
            if CPYUtilities.prepareSaveToPath(CPYUtilities.applicationSupportFolder()) {
                do {
                    let archivedData = try NSKeyedArchiver.archivedData(withRootObject: data, requiringSecureCoding: false)
                    try archivedData.write(to: URL(fileURLWithPath: savedPath))
                    dataService.upsertClip(clip)
                } catch {
                    print("Failed to archive clip data: \(error)")
                }
            }
        }
    }

    private func types(with pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        let types = pasteboard.types?.filter { canSave(with: $0) } ?? []
        return NSOrderedSet(array: types).array as? [NSPasteboard.PasteboardType] ?? []
    }

    private func canSave(with type: NSPasteboard.PasteboardType) -> Bool {
        let dictionary = CPYClipData.availableTypesDictinary
        guard let value = dictionary[type] else { return false }
        guard let number = storeTypes[value] else { return false }
        return number.boolValue
    }
}
