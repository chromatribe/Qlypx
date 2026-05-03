import Cocoa
import Combine

extension Notification.Name {
    static let clipsUpdated = Notification.Name("com.qlypx.app.DataService.clipsUpdated")
    static let snippetsUpdated = Notification.Name("com.qlypx.app.DataService.snippetsUpdated")
}

final class DataService {

    // MARK: - Properties
    private let clipsQueue = DispatchQueue(label: "com.qlypx.app.DataService.clips", qos: .background)
    private let snippetsQueue = DispatchQueue(label: "com.qlypx.app.DataService.snippets", qos: .background)
    private var cancellables = Set<AnyCancellable>()
    private let defaults: UserDefaults

    private(set) var clips: [CPYClip] = []
    private(set) var folders: [CPYFolder] = []

    private let storageDirectory: String

    private var clipsPath: String {
        return (storageDirectory as NSString).appendingPathComponent("clips.json")
    }

    private var snippetsPath: String {
        return (storageDirectory as NSString).appendingPathComponent("snippets.json")
    }

    // MARK: - Initialize
    init(defaults: UserDefaults = .standard, storageDirectory: String = CPYUtilities.applicationSupportFolder()) {
        self.defaults = defaults
        self.storageDirectory = storageDirectory
        loadData()
        bind()
    }

    private func bind() {
        defaults.qly_observe(Int.self, Constants.UserDefaults.maxHistorySize)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.trimHistory()
            }
            .store(in: &cancellables)
    }

    // MARK: - Load & Save
    func loadData() {
        // Load Clips
        if let data = try? Data(contentsOf: URL(fileURLWithPath: clipsPath)),
           let decoded = try? JSONDecoder().decode([CPYClip].self, from: data) {
            clips = decoded
        }

        // Load Snippets/Folders
        if let data = try? Data(contentsOf: URL(fileURLWithPath: snippetsPath)),
           let decoded = try? JSONDecoder().decode([CPYFolder].self, from: data) {
            folders = decoded
        }
    }

    func saveClips() {
        let clipsToSave = clips
        clipsQueue.async {
            if let data = try? JSONEncoder().encode(clipsToSave) {
                try? data.write(to: URL(fileURLWithPath: self.clipsPath))
                NotificationCenter.default.post(name: .clipsUpdated, object: nil)
            }
        }
    }

    func saveSnippets() {
        let foldersToSave = folders
        snippetsQueue.async {
            if let data = try? JSONEncoder().encode(foldersToSave) {
                try? data.write(to: URL(fileURLWithPath: self.snippetsPath))
                NotificationCenter.default.post(name: .snippetsUpdated, object: nil)
            }
        }
    }

    // MARK: - Clips Actions
    func upsertClip(_ clip: CPYClip) {
        if let index = clips.firstIndex(where: { $0.dataHash == clip.dataHash }) {
            let existingClip = clips[index]
            // If the data paths are different, delete the old data file
            if existingClip.dataPath != clip.dataPath {
                CPYUtilities.deleteData(at: existingClip.fullDataPath)
            }
            clips.remove(at: index)
        }
        clips.insert(clip, at: 0)
        trimHistory()
    }

    func trimHistory() {
        // Limit history size
        let maxSize = defaults.integer(forKey: Constants.UserDefaults.maxHistorySize)
        if clips.count > maxSize {
            let clipsToRemove = clips.suffix(from: maxSize)
            clipsToRemove.forEach { clipToRemove in
                CPYUtilities.deleteData(at: clipToRemove.fullDataPath)
                if !clipToRemove.thumbnailPath.isEmpty {
                    ImageCacheService.shared.removeImage(forKey: clipToRemove.thumbnailPath)
                }
            }
            clips = Array(clips.prefix(maxSize))
        }
        saveClips()
    }

    func deleteClip(with dataHash: String) {
        if let index = clips.firstIndex(where: { $0.dataHash == dataHash }) {
            let clip = clips[index]
            CPYUtilities.deleteData(at: clip.fullDataPath)
            clips.remove(at: index)
            saveClips()
        }
    }

    func clearAllClips() {
        clips.forEach { CPYUtilities.deleteData(at: $0.fullDataPath) }
        clips.removeAll()
        saveClips()
    }

    // MARK: - Snippets Actions
    func upsertFolder(_ folder: CPYFolder) {
        if let index = folders.firstIndex(where: { $0.identifier == folder.identifier }) {
            folders[index] = folder
        } else {
            folders.append(folder)
        }
        saveSnippets()
    }

    func deleteFolder(with identifier: String) {
        folders.removeAll(where: { $0.identifier == identifier })
        saveSnippets()
    }

    func updateFolders(_ newFolders: [CPYFolder]) {
        folders = newFolders
        saveSnippets()
    }
}
