//
//  ScreenShotObserver.swift
//  Qlypx
//

import Foundation

protocol ScreenShotObserverDelegate: AnyObject {
    func screenShotObserver(_ observer: ScreenShotObserver, addedItem item: NSMetadataItem)
}

final class ScreenShotObserver: NSObject {
    
    // MARK: - Properties
    weak var delegate: ScreenShotObserverDelegate?
    private let query = NSMetadataQuery()
    
    // MARK: - Init
    override init() {
        super.init()
        setupQuery()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Setup
    private func setupQuery() {
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1")
        query.operationQueue = .main
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(queryDidUpdate),
                                               name: .NSMetadataQueryDidUpdate,
                                               object: query)
        
        query.start()
    }
    
    func stop() {
        query.stop()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification
    @objc private func queryDidUpdate(_ notification: Notification) {
        guard let addedItems = notification.userInfo?[NSMetadataQueryUpdateAddedItemsKey] as? [NSMetadataItem] else { return }
        
        for item in addedItems {
            delegate?.screenShotObserver(self, addedItem: item)
        }
    }
}
