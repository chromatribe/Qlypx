import Foundation

extension NSCoding {
    func archive() -> Data {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            return data
        } catch {
            return Data()
        }
    }
}

extension Array where Element: NSCoding {
    func archive() -> Data {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
            return data
        } catch {
            return Data()
        }
    }
}
