//
//  PendingPurchasesService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

final class PendingPurchasesService {
    static let shared = PendingPurchasesService()
    
    private init() {}
    
    func fetchPendingPurchases(settings: NetworkSettings) async throws -> PendingPurchasesResponse {
        let data = try await NetworkService.shared.get(
            from: settings.authenticatedPendingURL
        )
        
        return try JSONDecoder().decode(
            PendingPurchasesResponse.self,
            from: data
        )
    }
    
  
    
    func markFulfilled(
        settings: NetworkSettings,
        transactionID: String
    ) async throws {
        let url = settings.authenticatedFulfilledURL(
            transactionID: transactionID
        )
        
        print("Mark fulfilled URL:", url)
        
        _ = try await NetworkService.shared.get(from: url)
    }
}
