//
//  HealthService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

final class HealthService {
    
    static let shared = HealthService()
    
    private init() { }
    
    func checkServer(
        at url: String
    ) async throws -> HealthResponse {
        
        let data =
        try await NetworkService.shared
            .get(from: url)
        
        return try JSONDecoder()
            .decode(
                HealthResponse.self,
                from: data
            )
    }
}
