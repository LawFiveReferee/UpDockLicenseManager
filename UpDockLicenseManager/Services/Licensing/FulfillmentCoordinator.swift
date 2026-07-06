//
//  FulfillmentCoordinator.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

struct PendingPurchaseFulfillmentResult {
  var createdLicenses: [LicenseRecord]
  var updatedExistingLicenses: [LicenseRecord]
  var serverResponse: FulfilledPurchaseResponse

  var didCreateLicense: Bool {
    !createdLicenses.isEmpty
  }

  var savedLicenses: [LicenseRecord] {
    updatedExistingLicenses + createdLicenses
  }

  var statusMessage: String {
    if serverResponse.alreadyFulfilled && createdLicenses.isEmpty {
      return "Transaction was already archived. Showing existing license records."
    }

    if serverResponse.alreadyFulfilled {
      return "Transaction was already archived. Created \(createdLicenses.count) missing local license record\(createdLicenses.count == 1 ? "" : "s")."
    }

    return "Purchase fulfilled and archived. Created \(createdLicenses.count) license\(createdLicenses.count == 1 ? "" : "s")."
  }
}

final class FulfillmentCoordinator {
  static let shared = FulfillmentCoordinator()

  private init() {}

  func fulfillPendingPurchase(
    _ purchase: PendingPaddlePurchase,
    settings: NetworkSettings,
    existingLicensesForTransactionID: (String) -> [LicenseRecord]
  ) async throws -> PendingPurchaseFulfillmentResult {
    let serverResponse = try await PendingPurchasesService.shared.markFulfilled(
      settings: settings,
      transactionID: purchase.transactionID
    )

    let existingLicenses = existingLicensesForTransactionID(purchase.transactionID)
    let updatedExistingLicenses = existingLicenses.map { existingLicense in
      var updatedLicense = existingLicense
      updatedLicense.fulfillmentArchiveStatus = .archived
      updatedLicense.fulfillmentArchiveCheckedAt = Date()
      updatedLicense.fulfilledAt = updatedLicense.fulfilledAt ?? Date()
      return updatedLicense
    }
    let missingLicenseCount = max(purchase.licenseQuantity - existingLicenses.count, 0)
    let createdLicenses = (0..<missingLicenseCount).map { index in
      makeCommercialLicenseRecord(from: purchase, seatNumber: index + existingLicenses.count + 1)
    }

    return PendingPurchaseFulfillmentResult(
      createdLicenses: createdLicenses,
      updatedExistingLicenses: updatedExistingLicenses,
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
    from purchase: PendingPaddlePurchase,
    seatNumber: Int = 1
  ) -> LicenseRecord {
    let transaction = purchase.payload.data
    let customer = transaction?.customer
    let item = transaction?.primaryItem
    let quantity = purchase.licenseQuantity

    let name = transaction?.customerName ?? ""
    let email = transaction?.customerEmail ?? ""
    let seatNote = quantity > 1 ? " Seat \(seatNumber) of \(quantity)." : ""

    return LicenseRecord(
      serial: LicenseGenerator.makeSerial(type: .commercial),
      type: .commercial,
      name: name,
      email: email,
      expiresAt: nil,
      notes: "Created from pending Paddle purchase.\(seatNote)",
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
