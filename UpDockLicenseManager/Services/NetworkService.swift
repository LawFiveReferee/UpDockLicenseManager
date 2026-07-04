//
//  NetworkService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

enum NetworkServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
            
        case .invalidResponse:
            return "Invalid server response."
            
        case .serverError(let code):
            return "Server returned HTTP \(code)."
        }
    }
}

final class NetworkService {
    
    static let shared = NetworkService()
    
    private init() { }
    
    func get(
        from urlString: String
    ) async throws -> Data {
        
        guard let url = URL(string: urlString) else {
            throw NetworkServiceError.invalidURL
        }
        
        let (data, response) =
        try await URLSession.shared.data(from: url)
        
        guard
            let http =
                response as? HTTPURLResponse
        else {
            throw NetworkServiceError.invalidResponse
        }
        
        guard
            http.statusCode == 200
        else {
            throw NetworkServiceError.serverError(
                http.statusCode
            )
        }
        
        return data
    }
    func postJSON(
        to urlString: String,
        body: Data
    ) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkServiceError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkServiceError.invalidResponse
        }
        
        guard http.statusCode == 200 else {
            throw NetworkServiceError.serverError(http.statusCode)
        }
        
        return data
    }
}
