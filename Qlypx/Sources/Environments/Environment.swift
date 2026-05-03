//
//  Environment.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://qlypx-app.com
//
//  Created by Econa77 on 2017/08/10.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation

struct Environment {

    // MARK: - Properties
    let dataService: DataService
    let clipService: ClipService
    let hotKeyService: HotKeyService
    let dataCleanService: DataCleanService
    let pasteService: PasteService
    let excludeAppService: ExcludeAppService
    let accessibilityService: AccessibilityService
    let updateService: UpdateService
    let diagnosticService: DiagnosticService
    let menuManager: MenuManager

    let defaults: UserDefaults

    // MARK: - Initialize
    init(dataService: DataService = DataService(),
         clipService: ClipService = ClipService(),
         hotKeyService: HotKeyService = HotKeyService(),
         dataCleanService: DataCleanService = DataCleanService(),
         pasteService: PasteService = PasteService(),
         excludeAppService: ExcludeAppService = ExcludeAppService(applications: []),
         accessibilityService: AccessibilityService = AccessibilityService(),
         updateService: UpdateService = UpdateService(),
         diagnosticService: DiagnosticService = DiagnosticService.shared,
         menuManager: MenuManager = MenuManager(),
         defaults: UserDefaults = .standard) {

        self.dataService = dataService
        self.clipService = clipService
        self.hotKeyService = hotKeyService
        self.dataCleanService = dataCleanService
        self.pasteService = pasteService
        self.excludeAppService = excludeAppService
        self.accessibilityService = accessibilityService
        self.updateService = updateService
        self.diagnosticService = diagnosticService
        self.menuManager = menuManager
        self.defaults = defaults
    }

}
