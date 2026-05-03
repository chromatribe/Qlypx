//
//  CPYDesignableButton.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2016/02/26.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Cocoa

class CPYDesignableButton: NSButton {

    @IBInspectable var textColor: NSColor = ColorName.title.color

    // MARK: - Initialize
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        initView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initView()
    }

    private func initView() {
        let attributedString = NSAttributedString(string: title, attributes: [.foregroundColor: textColor])
        attributedTitle = attributedString
    }
}
