//
//  CPYTypePreferenceViewController.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2016/03/17.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa

class CPYTypePreferenceViewController: NSViewController {

    // MARK: - Properties
    @objc var storeTypes: NSMutableDictionary!

    // MARK: - Initialize
    override func loadView() {
        if let dictionary = AppEnvironment.current.defaults.object(forKey: Constants.UserDefaults.storeTypes) as? [String: Any] {
            storeTypes = NSMutableDictionary(dictionary: dictionary)
        } else {
            storeTypes = NSMutableDictionary()
        }
        super.loadView()
    }

}
