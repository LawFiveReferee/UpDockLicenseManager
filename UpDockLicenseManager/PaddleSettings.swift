//
//  PaddleSettings.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/2/26.
//
import Foundation
import Observation

@Observable
final class PaddleSettings {
    
    enum Environment: String, CaseIterable, Codable, Identifiable {
        case sandbox = "Sandbox"
        case production = "Production"
        
        var id: String { rawValue }
    }
    
    var environment: Environment {
        didSet { save() }
    }
    
    var defaultProductID: String {
        didSet { save() }
    }
    
    var defaultPriceID: String {
        didSet { save() }
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        environment = Environment(
            rawValue: defaults.string(forKey: "paddle.environment") ?? "Sandbox"
        ) ?? .sandbox
        
        defaultProductID = defaults.string(forKey: "paddle.product") ?? ""
        defaultPriceID = defaults.string(forKey: "paddle.price") ?? ""
    }
    
    private func save() {
        defaults.set(environment.rawValue, forKey: "paddle.environment")
        defaults.set(defaultProductID, forKey: "paddle.product")
        defaults.set(defaultPriceID, forKey: "paddle.price")
    }
}
