import Foundation
import Combine

extension UserDefaults {
    /// Observe changes to a specific key in UserDefaults using Combine.
    /// Emits the current value immediately, then whenever the key changes.
    /// - Parameters:
    ///   - type: The type of the value to observe.
    ///   - key: The UserDefaults key string to observe.
    /// - Returns: A publisher that emits the value whenever it changes.
    func qly_observe<T>(_ type: T.Type, _ key: String) -> AnyPublisher<T?, Never> {
        return NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification, object: self)
            .compactMap { notification -> Bool? in
                // If we can identify specific changed keys, filter; otherwise emit
                guard let keys = (notification.userInfo?["NSChangedKeys"] as? Set<String>) else {
                    return true
                }
                return keys.contains(key) ? true : nil
            }
            .map { [weak self] _ in self?.object(forKey: key) as? T }
            .prepend(object(forKey: key) as? T)
            .eraseToAnyPublisher()
    }
}

extension NotificationCenter {
    /// A wrapper for publisher(for:object:) that returns a Void publisher for notifications with no data.
    func publisher(for name: Notification.Name) -> AnyPublisher<Void, Never> {
        return self.publisher(for: name, object: nil)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
