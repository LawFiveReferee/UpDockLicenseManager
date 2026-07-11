 
//
//  GeneralSettings.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/2/26.
//

import Foundation
import Observation

@Observable
final class GeneralSettings {
    var organizationName: String {
        didSet { save() }
    }
    
    var productName: String {
        didSet { save() }
    }
    
    var supportEmail: String {
        didSet { save() }
    }
    
    var defaultTrialLengthDays: Int {
        didSet { save() }
    }
    
    var defaultBetaLengthDays: Int {
        didSet { save() }
    }

    var showToolbarTextLabels: Bool {
        didSet { save() }
    }

    var showDevelopmentTools: Bool {
        didSet { save() }
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        self.organizationName = defaults.string(forKey: "organizationName") ?? "Stockly Consulting"
        self.productName = defaults.string(forKey: "productName") ?? "UpDock Pro"
        self.supportEmail = defaults.string(forKey: "supportEmail") ?? "customerservice@updockapp.com"
        self.defaultTrialLengthDays = defaults.object(forKey: "defaultTrialLengthDays") as? Int ?? 30
        self.defaultBetaLengthDays = defaults.object(forKey: "defaultBetaLengthDays") as? Int ?? 90
        self.showToolbarTextLabels = defaults.object(forKey: "showToolbarTextLabels") as? Bool ?? false
        self.showDevelopmentTools = defaults.object(forKey: "showDevelopmentTools") as? Bool ?? false
    }
    
    private func save() {
        defaults.set(organizationName, forKey: "organizationName")
        defaults.set(productName, forKey: "productName")
        defaults.set(supportEmail, forKey: "supportEmail")
        defaults.set(defaultTrialLengthDays, forKey: "defaultTrialLengthDays")
        defaults.set(defaultBetaLengthDays, forKey: "defaultBetaLengthDays")
        defaults.set(showToolbarTextLabels, forKey: "showToolbarTextLabels")
        defaults.set(showDevelopmentTools, forKey: "showDevelopmentTools")
    }
}
