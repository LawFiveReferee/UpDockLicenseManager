//
//  ServerService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/4/26.
//

import Foundation

enum ServerDevAction: String {
    case generate = "generate"
    case clearPending = "clear-pending"
    case clearFulfilled = "clear-fulfilled"
    case clearAll = "clear-all"
    case status = "status"
}

final class ServerService {
    static let shared = ServerService()
    
    private init() {}
    
    func devToolsURL(
        settings: NetworkSettings,
        action: ServerDevAction,
        count: Int? = nil
    ) -> String {
        let token = KeychainSettingsStore.shared.managerToken
        
        var components = URLComponents(string: settings.serverBaseURL + "/dev-tools.php")
        var queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "action", value: action.rawValue)
        ]
        
        if let count {
            queryItems.append(
                URLQueryItem(name: "count", value: "\(count)")
            )
        }
        
        components?.queryItems = queryItems
        
        return components?.url?.absoluteString ?? ""
    }
    
    func generateTestPurchases(
        settings: NetworkSettings,
        count: Int
    ) async throws {
        _ = try await NetworkService.shared.get(
            from: devToolsURL(
                settings: settings,
                action: .generate,
                count: count
            )
        )
    }
    
    func clearPendingTestPurchases(settings: NetworkSettings) async throws {
        _ = try await NetworkService.shared.get(
            from: devToolsURL(settings: settings, action: .clearPending)
        )
    }
    
    func clearFulfilledTestPurchases(settings: NetworkSettings) async throws {
        _ = try await NetworkService.shared.get(
            from: devToolsURL(settings: settings, action: .clearFulfilled)
        )
    }
    
    func clearAllTestPurchases(settings: NetworkSettings) async throws {
        _ = try await NetworkService.shared.get(
            from: devToolsURL(settings: settings, action: .clearAll)
        )
    }
}
