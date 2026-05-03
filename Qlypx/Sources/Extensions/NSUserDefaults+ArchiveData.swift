//
//  NSUserDefaults+ArchiveData.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2016/06/23.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation
import Cocoa
import Combine

extension UserDefaults {
    func setArchiveData<T: NSCoding>(_ object: T, forKey key: String) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: object, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            QlyLogger.error("Failed to archive data for key \(key): \(error)")
        }
    }

    func archiveDataForKey<T: NSCoding>(_: T.Type, key: String) -> T? {
        guard let data = object(forKey: key) as? Data else { return nil }
        do {
            let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            return unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? T
        } catch {
            QlyLogger.error("Failed to unarchive data for key \(key): \(error)")
            return nil
        }
    }

    func qly_observe<T>(_ type: T.Type, _ key: String) -> AnyPublisher<T?, Never> {
        return NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: self)
            .map { ($0.object as? UserDefaults)?.object(forKey: key) as? T }
            .prepend(self.object(forKey: key) as? T)
            .eraseToAnyPublisher()
    }
}
