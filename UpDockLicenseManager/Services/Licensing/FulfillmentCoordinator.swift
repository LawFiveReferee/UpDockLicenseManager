//
//  FulfillmentCoordinator.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

struct PendingPurchaseFulfillmentResult {
  var license: LicenseRecord
  var didCreateLicense: Bool
  var serverResponse: FulfilledPurchaseResponse

  var statusMessage: String {
    if let message = serverResponse.message, !message.isEmpty {
      return message
    }

    if serverResponse.alreadyFulfilled && !didCreateLicense {
      return "Transaction was already archived. Showing the existing license."
    }

    if serverResponse.alreadyFulfilled {
      return "Transaction was already archived. Created a local license record."
    }

    return "Purchase fulfilled and archived."
  }
}

final class FulfillmentCoordinator {
  static let shared = FulfillmentCoordinator()

  private init() {}

  func fulfillPendingPurchase(
    _ purchase: PendingPaddlePurchase,
    settings: NetworkSettings,
    existingLicenseForTransactionID: (String) -> LicenseRecord?
  ) async throws -> PendingPurchaseFulfillmentResult {
    let serverResponse = try await PendingPurchasesService.shared.markFulfilled(
      settings: settings,
      transactionID: purchase.transactionID
    )

    if let existingLicense = existingLicenseForTransactionID(purchase.transactionID) {
      var updatedLicense = existingLicense
      updatedLicense.fulfillmentArchiveStatus = .archived
      updatedLicense.fulfillmentArchiveCheckedAt = Date()
      updatedLicense.fulfilledAt = updatedLicense.fulfilledAt ?? Date()

      return PendingPurchaseFulfillmentResult(
        license: updatedLicense,
        didCreateLicense: false,
        serverResponse: serverResponse
      )
    }

    return PendingPurchaseFulfillmentResult(
      license: makeCommercialLicenseRecord(from: purchase),
      didCreateLicense: true,
      serverResponse: serverResponse
    )
  }

  func verifyFulfillmentArchive(
    for license: LicenseRecord,
    settings: NetworkSettings
  ) async throws -> LicenseRecord {
    let transactionID = license.paddleTransactionID.trimmingCharacters(
      in: .whitespacesAndNewlines
    )

    guard !transactionID.isEmpty else {
      return license
    }

    let verification = try await PendingPurchasesService.shared.verifyFulfillmentArchive(
      settings: settings,
      transactionID: transactionID
    )
    var updatedLicense = license

    updatedLicense.fulfillmentArchiveStatus = verification.status
    updatedLicense.fulfillmentArchiveCheckedAt = verification.checkedAt

    if verification.status == .archived {
      updatedLicense.fulfilledAt = updatedLicense.fulfilledAt ?? verification.checkedAt
    }

    return updatedLicense
  }

  func makeCommercialLicenseRecord(
    from purchase: PendingPaddlePurchase
  ) -> LicenseRecord {
    let transaction = purchase.payload.data
    let customer = transaction?.customer
    let item = transaction?.primaryItem

    let name = transaction?.customerName ?? ""
    let email = transaction?.customerEmail ?? ""

    return LicenseRecord(
      serial: LicenseGenerator.makeSerial(type: .commercial),
      type: .commercial,
      name: name,
      email: email,
      expiresAt: nil,
      notes: "Created from pending Paddle purchase.",
      paddleCustomerID: transaction?.customerID ?? customer?.id ?? "",
      paddleTransactionID: purchase.transactionID,
      paddleEmail: email,
      paddleProductID: item?.product?.id ?? item?.price?.productID ?? "",
      paddlePriceID: item?.price?.id ?? "",
      paddleStatus: transaction?.status ?? "",
      fulfilledAt: Date(),
      fulfillmentArchiveStatus: .archived,
      fulfillmentArchiveCheckedAt: Date()
    )
  }
}
