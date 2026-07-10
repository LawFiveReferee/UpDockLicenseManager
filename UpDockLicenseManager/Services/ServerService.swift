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

  func fetchOperationsStatus(
    settings: NetworkSettings,
    managerToken: String
  ) async throws -> OperationsStatusResponse {
    let data = try await NetworkService.shared.get(
      from: settings.authenticatedOperationsStatusURL(token: managerToken)
    )

    return try JSONDecoder().decode(OperationsStatusResponse.self, from: data)
  }

  func sendTestLicenseEmail(
    settings: NetworkSettings,
    recipient: String
  ) async throws -> ServerEmailTestResponse {
    let data = try await NetworkService.shared.get(
      from: settings.authenticatedTestLicenseEmailURL(email: recipient)
    )

    return try JSONDecoder().decode(ServerEmailTestResponse.self, from: data)
  }

  func runActivationLimitTest(
    settings: NetworkSettings,
    serial: String,
    seatAllowance: Int
  ) async -> [ActivationTestStep] {
    let steps = [
      ActivationTestRequest(
        title: "Register License",
        url: settings.activationRegisterURL(serial: serial, seatAllowance: seatAllowance),
        expectedStatusCode: 200
      ),
      ActivationTestRequest(
        title: "Activate Mac 1",
        url: settings.activationURL(serial: serial, machineID: "mac-1", machineName: "Mac 1"),
        expectedStatusCode: 200
      ),
      ActivationTestRequest(
        title: "Activate Mac 2",
        url: settings.activationURL(serial: serial, machineID: "mac-2", machineName: "Mac 2"),
        expectedStatusCode: 200
      ),
      ActivationTestRequest(
        title: "Reject Mac 3",
        url: settings.activationURL(serial: serial, machineID: "mac-3", machineName: "Mac 3"),
        expectedStatusCode: 409
      ),
      ActivationTestRequest(
        title: "Status",
        url: settings.activationStatusURL(serial: serial),
        expectedStatusCode: 200
      )
    ]

    var results: [ActivationTestStep] = []

    for step in steps {
      results.append(await runActivationTestStep(step))
    }

    return results
  }

  private func runActivationTestStep(_ request: ActivationTestRequest) async -> ActivationTestStep {
    guard let url = URL(string: request.url) else {
      return ActivationTestStep(
        title: request.title,
        statusCode: nil,
        expectedStatusCode: request.expectedStatusCode,
        responseSummary: "Invalid URL"
      )
    }

    do {
      let (_, response) = try await URLSession.shared.data(from: url)
      guard let httpResponse = response as? HTTPURLResponse else {
        return ActivationTestStep(
          title: request.title,
          statusCode: nil,
          expectedStatusCode: request.expectedStatusCode,
          responseSummary: "Invalid server response"
        )
      }

      return ActivationTestStep(
        title: request.title,
        statusCode: httpResponse.statusCode,
        expectedStatusCode: request.expectedStatusCode,
        responseSummary: httpResponse.statusCode == request.expectedStatusCode ? "Expected" : "Unexpected"
      )
    } catch {
      return ActivationTestStep(
        title: request.title,
        statusCode: nil,
        expectedStatusCode: request.expectedStatusCode,
        responseSummary: error.localizedDescription
      )
    }
  }
}

struct ServerEmailTestResponse: Codable {
  var status: String
  var apiVersion: Int?
  var sent: Bool
  var recipient: String
  var attachment: String?
  var message: String?
}

final class ActivationRegistryService {
  static let shared = ActivationRegistryService()

  private init() {}

  func registerLicense(
    _ license: LicenseRecord,
    settings: NetworkSettings
  ) async throws -> LicenseRecord {
    guard let seatAllowance = license.seatAllowance else {
      var updatedLicense = license
      updatedLicense.activationRegistryStatus = .notRequired
      updatedLicense.activationRegistryCheckedAt = Date()
      updatedLicense.activationRegistryError = ""
      return updatedLicense
    }

    _ = try await NetworkService.shared.get(
      from: registrationURL(
        license: license,
        seatAllowance: seatAllowance,
        settings: settings
      )
    )

    var updatedLicense = license
    updatedLicense.activationRegistryStatus = .registered
    updatedLicense.activationRegistryCheckedAt = Date()
    updatedLicense.activationRegistryError = ""
    return updatedLicense
  }

  private func registrationURL(
    license: LicenseRecord,
    seatAllowance: Int,
    settings: NetworkSettings
  ) -> String {
    let token = KeychainSettingsStore.shared.managerToken
    var components = URLComponents(string: settings.licenseRegisterURL)
    components?.queryItems = [
      URLQueryItem(name: "token", value: token),
      URLQueryItem(name: "serial", value: license.serial),
      URLQueryItem(name: "seat_allowance", value: "\(seatAllowance)"),
      URLQueryItem(name: "product", value: license.product),
      URLQueryItem(name: "customer_name", value: license.name),
      URLQueryItem(name: "customer_email", value: license.email),
      URLQueryItem(name: "paddle_transaction_id", value: license.paddleTransactionID)
    ]

    return components?.url?.absoluteString ?? ""
  }
}

private struct ActivationTestRequest {
  let title: String
  let url: String
  let expectedStatusCode: Int
}

struct ActivationTestStep: Identifiable, Hashable {
  let id = UUID()
  let title: String
  let statusCode: Int?
  let expectedStatusCode: Int
  let responseSummary: String

  var passed: Bool {
    statusCode == expectedStatusCode
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

struct OperationsStatusResponse: Decodable {
  var status: String
  var apiVersion: Int?
  var generatedAt: String
  var counts: OperationsStatusCounts
  var latest: OperationsStatusLatest
  var storage: OperationsStatusStorage
}

struct OperationsStatusCounts: Decodable {
  var pendingTransactions: Int
  var fulfilledTransactions: Int
  var registeredLicenses: Int
  var activeActivations: Int
}

struct OperationsStatusLatest: Decodable {
  var pendingTransactions: [OperationsStatusFileSummary]
  var fulfilledTransactions: [OperationsStatusFileSummary]
  var registeredLicenses: [OperationsStatusFileSummary]
  var webhookEvents: [OperationsStatusWebhookEvent]
}

struct OperationsStatusFileSummary: Decodable, Identifiable, Hashable {
  var id: String
  var updatedAt: String
  var file: String
}

struct OperationsStatusWebhookEvent: Decodable, Identifiable, Hashable {
  var time: String?
  var status: String
  var message: String
  var context: [String: String]?

  var id: String {
    [
      time ?? "",
      status,
      message,
      context?["transaction_id"] ?? "",
      context?["event_type"] ?? ""
    ].joined(separator: "|")
  }
}

struct OperationsStatusStorage: Decodable {
  var transactionsWritable: Bool
  var fulfilledWritable: Bool
  var licensesWritable: Bool
  var activationsWritable: Bool
  var webhookLogWritable: Bool
}
