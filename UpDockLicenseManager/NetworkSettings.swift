//
//  NetworkSettings.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation
import Observation

@Observable
final class NetworkSettings {
    
    var serverBaseURL: String {
        didSet { save() }
    }
    
    private let defaults = UserDefaults.standard
    
    init() {
        serverBaseURL =
        defaults.string(forKey: "network.serverBaseURL")
        ?? "https://updockapp.com/paddle"
    }
    
    private func save() {
        defaults.set(
            serverBaseURL,
            forKey: "network.serverBaseURL"
        )
    }
    
    var healthURL: String {
        serverBaseURL + "/health.php"
    }
    
    var pendingURL: String {
        serverBaseURL + "/pending.php"
    }
    
    var authenticatedPendingURL: String {
        let token = KeychainSettingsStore.shared.managerToken
        
        guard !token.isEmpty else {
            return pendingURL + "?token="
        }
        
        return pendingURL + "?token=" + token
    }
    
    var authenticatedFulfilledURL: String {
        let token = KeychainSettingsStore.shared.managerToken
        
        guard !token.isEmpty else {
            return fulfilledURL + "?token="
        }
        
        return fulfilledURL + "?token=" + token
    }
    
    var fulfilledURL: String {
        serverBaseURL + "/fulfilled.php"
    }
    
    var webhookURL: String {
        serverBaseURL + "/webhook.php"
    }
    var simulateURL: String {
        serverBaseURL + "/simulate.php"
    }
    
    func authenticatedFulfilledURL(transactionID: String) -> String {
        let token = KeychainSettingsStore.shared.managerToken
        
        var components = URLComponents(string: fulfilledURL)
        components?.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "transaction_id", value: transactionID)
        ]
        
        return components?.url?.absoluteString ?? ""
    }
    
    func authenticatedPendingURLString() -> String {
        authenticatedPendingURL
    }
    
    func authenticatedSimulateURL(count: Int) -> String {
        let token = KeychainSettingsStore.shared.managerToken
        return simulateURL + "?token=" + token + "&count=\(count)"
    }
}
