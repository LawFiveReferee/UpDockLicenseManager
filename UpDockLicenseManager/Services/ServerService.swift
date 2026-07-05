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
  case webhookLog = "webhook-log"
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

  func fetchWebhookLog(settings: NetworkSettings) async throws -> WebhookLogResponse {
    let data = try await NetworkService.shared.get(
      from: devToolsURL(settings: settings, action: .webhookLog)
    )

    return try JSONDecoder().decode(WebhookLogResponse.self, from: data)
  }
}

struct WebhookLogResponse: Decodable {
  let status: String
  let apiVersion: Int?
  let entries: [WebhookLogEntry]
}

struct WebhookLogEntry: Decodable, Identifiable, Hashable {
  let time: String
  let status: String
  let message: String
  let context: [String: String]?

  var id: String {
    [
      time,
      status,
      message,
      context?["transaction_id"] ?? "",
      context?["event_type"] ?? ""
    ].joined(separator: "|")
  }
}
