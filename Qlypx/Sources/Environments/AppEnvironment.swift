//
//  AppEnvironment.swift
//
//  Qlypx
//  GitHub: https://github.com/qlypx
//  HP: https://chromatri.be
//
//  Created by Econa77 on 2017/08/10.
//
//  Copyright © 2015-2018 Qlypx Project.
//

import Foundation

struct AppEnvironment {

    // MARK: - Properties
    private static var stack = [Environment()]

    static var current: Environment {
        return stack.last ?? Environment()
    }

    // MARK: - Stacks
    static func push(environment: Environment) {
        stack.append(environment)
    }

    @discardableResult
    static func popLast() -> Environment? {
        return stack.popLast()
    }

    static func replaceCurrent(environment: Environment) {
        push(environment: environment)
        stack.remove(at: stack.count - 2)
    }

    static func push(dataService: DataService = current.dataService,
                     clipService: ClipService = current.clipService,
                     hotKeyService: HotKeyService = current.hotKeyService,
                     dataCleanService: DataCleanService = current.dataCleanService,
                     pasteService: PasteService = current.pasteService,
                     excludeAppService: ExcludeAppService = current.excludeAppService,
                     accessibilityService: AccessibilityService = current.accessibilityService,
                     updateService: UpdateService = current.updateService,
                     diagnosticService: DiagnosticService = current.diagnosticService,
                     menuManager: MenuManager = current.menuManager,
                     defaults: UserDefaults = current.defaults) {
        push(environment: Environment(dataService: dataService,
                                      clipService: clipService,
                                      hotKeyService: hotKeyService,
                                      dataCleanService: dataCleanService,
                                      pasteService: pasteService,
                                      excludeAppService: excludeAppService,
                                      accessibilityService: accessibilityService,
                                      updateService: updateService,
                                      diagnosticService: diagnosticService,
                                      menuManager: menuManager,
                                      defaults: defaults))
    }

    static func replaceCurrent(dataService: DataService = current.dataService,
                               clipService: ClipService = current.clipService,
                               hotKeyService: HotKeyService = current.hotKeyService,
                               dataCleanService: DataCleanService = current.dataCleanService,
                               pasteService: PasteService = current.pasteService,
                               excludeAppService: ExcludeAppService = current.excludeAppService,
                               accessibilityService: AccessibilityService = current.accessibilityService,
                               updateService: UpdateService = current.updateService,
                               diagnosticService: DiagnosticService = current.diagnosticService,
                               menuManager: MenuManager = current.menuManager,
                               defaults: UserDefaults = current.defaults) {
        replaceCurrent(environment: Environment(dataService: dataService,
                                                clipService: clipService,
                                                hotKeyService: hotKeyService,
                                                dataCleanService: dataCleanService,
                                                pasteService: pasteService,
                                                excludeAppService: excludeAppService,
                                                accessibilityService: accessibilityService,
                                                updateService: updateService,
                                                diagnosticService: diagnosticService,
                                                menuManager: menuManager,
                                                defaults: defaults))
    }

    static func fromStorage(defaults: UserDefaults = .standard) -> Environment {
        var excludeApplications = [QLYAppInfo]()
        if let data = defaults.object(forKey: Constants.UserDefaults.excludeApplications) as? Data {
            do {
                if let applications = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, QLYAppInfo.self, NSString.self], from: data) as? [QLYAppInfo] {
                    excludeApplications = applications
                }
            } catch {
                QlyLogger.error("Failed to unarchive excludeApplications: \(error)", log: .environment)
            }
        }
        let excludeAppService = ExcludeAppService(applications: excludeApplications)
        return Environment(dataService: current.dataService,
                           clipService: current.clipService,
                           hotKeyService: current.hotKeyService,
                           dataCleanService: current.dataCleanService,
                           pasteService: current.pasteService,
                           excludeAppService: excludeAppService,
                           accessibilityService: current.accessibilityService,
                           updateService: current.updateService,
                           diagnosticService: current.diagnosticService,
                           menuManager: current.menuManager,
                           defaults: current.defaults)
    }

 }
