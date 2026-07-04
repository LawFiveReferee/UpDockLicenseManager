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
  ) async throws -> FulfilledPurchaseResponse {
    let url = settings.authenticatedFulfilledURL(
      transactionID: transactionID
    )

    let data = try await NetworkService.shared.get(from: url)

    return (
      try? JSONDecoder().decode(
        FulfilledPurchaseResponse.self,
        from: data
      )
    ) ?? FulfilledPurchaseResponse(
      status: "ok",
      transactionID: transactionID
    )
  }

  func verifyFulfillmentArchive(
    settings: NetworkSettings,
    transactionID: String
  ) async throws -> FulfillmentArchiveVerification {
    let pendingResponse = try await fetchPendingPurchases(settings: settings)

    if pendingResponse.items.contains(where: { $0.transactionID == transactionID }) {
      return FulfillmentArchiveVerification(
        status: .pending,
        checkedAt: Date(),
        message: "Transaction is still in the pending queue."
      )
    }

    do {
      let response = try await markFulfilled(
        settings: settings,
        transactionID: transactionID
      )

      return FulfillmentArchiveVerification(
        status: .archived,
        checkedAt: Date(),
        message: response.message ?? "Transaction is in the fulfilled archive."
      )
    } catch NetworkServiceError.serverError(404) {
      return FulfillmentArchiveVerification(
        status: .notFound,
        checkedAt: Date(),
        message: "Transaction was not found in pending or fulfilled records."
      )
    }
  }
}

struct FulfillmentArchiveVerification: Hashable {
  var status: FulfillmentArchiveStatus
  var checkedAt: Date
  var message: String
}
