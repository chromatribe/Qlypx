import Foundation
import Cocoa

final class ImageCacheService {
    static let shared = ImageCacheService()
    
    private let memoryCache = NSCache<NSString, NSImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private let ioQueue = DispatchQueue(label: "com.qlypx.app.imagecache.io", qos: .background)
    
    private init() {
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("com.qlypx.app/Thumbnails")
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        // Setup memory cache limits
        memoryCache.countLimit = 100 // Cache up to 100 images in memory
    }
    
    func image(forKey key: String, completion: @escaping (String, NSImage?) -> Void) {
        if let image = memoryCache.object(forKey: key as NSString) {
            completion(key, image)
            return
        }
        
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            let fileURL = self.cacheDirectory.appendingPathComponent(key)
            if let data = try? Data(contentsOf: fileURL), let image = NSImage(data: data) {
                self.memoryCache.setObject(image, forKey: key as NSString)
                DispatchQueue.main.async {
                    completion(key, image)
                }
            } else {
                DispatchQueue.main.async {
                    completion(key, nil)
                }
            }
        }
    }
    
    func setImage(_ image: NSImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            let fileURL = self.cacheDirectory.appendingPathComponent(key)
            // Use tiffRepresentation as it's the standard for NSImage data
            if let data = image.tiffRepresentation {
                try? data.write(to: fileURL)
            }
        }
    }
    
    func removeImage(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            let fileURL = self.cacheDirectory.appendingPathComponent(key)
            if self.fileManager.fileExists(atPath: fileURL.path) {
                try? self.fileManager.removeItem(at: fileURL)
            }
        }
    }
}
