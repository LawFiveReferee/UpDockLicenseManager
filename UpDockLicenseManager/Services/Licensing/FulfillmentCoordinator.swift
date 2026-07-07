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
  var fulfillmentPolicy: PaddleFulfillmentPolicy

  var didCreateLicense: Bool {
    !createdLicenses.isEmpty
  }

  var savedLicenses: [LicenseRecord] {
    updatedExistingLicenses + createdLicenses
  }

  var activationRegistrationFailedCount: Int {
    savedLicenses.filter { $0.activationRegistryStatus == .failed }.count
  }

  var activationRegisteredCount: Int {
    savedLicenses.filter { $0.activationRegistryStatus == .registered }.count
  }

  var statusMessage: String {
    if serverResponse.alreadyFulfilled && createdLicenses.isEmpty {
      return "Transaction was already archived. Showing existing license records."
    }

    if serverResponse.alreadyFulfilled {
      return "Transaction was already archived. Created \(createdLicenses.count) missing local license record\(createdLicenses.count == 1 ? "" : "s")."
    }

    if fulfillmentPolicy.mode == .siteLicense {
      let baseMessage = "Purchase fulfilled and archived. Created site license for \(fulfillmentPolicy.purchasedQuantity) seat\(fulfillmentPolicy.purchasedQuantity == 1 ? "" : "s")."

      if activationRegistrationFailedCount > 0 {
        return baseMessage + " Activation registration needs attention."
      }

      if activationRegisteredCount > 0 {
        return baseMessage + " Activation registry updated."
      }

      return baseMessage
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

    let fulfillmentPolicy = PaddleFulfillmentPolicyStore().policy(for: purchase)
    let existingLicenses = existingLicensesForTransactionID(purchase.transactionID)
    let archiveUpdatedExistingLicenses = existingLicenses.map { existingLicense in
      var updatedLicense = existingLicense
      updatedLicense.fulfillmentArchiveStatus = .archived
      updatedLicense.fulfillmentArchiveCheckedAt = Date()
      updatedLicense.fulfilledAt = updatedLicense.fulfilledAt ?? Date()
      return updatedLicense
    }
    let missingLicenseCount = max(
      fulfillmentPolicy.generatedLicenseCount - existingLicenses.count,
      0
    )
    let createdLicenses = (0..<missingLicenseCount).map { index in
      makeCommercialLicenseRecord(
        from: purchase,
        fulfillmentPolicy: fulfillmentPolicy,
        seatNumber: index + existingLicenses.count + 1
      )
    }
    let registeredLicenses = await registerActivationRegistryIfNeeded(
      licenses: archiveUpdatedExistingLicenses + createdLicenses,
      settings: settings
    )
    let updatedExistingLicenses = Array(
      registeredLicenses.prefix(archiveUpdatedExistingLicenses.count)
    )
    let activationUpdatedCreatedLicenses = Array(
      registeredLicenses.dropFirst(archiveUpdatedExistingLicenses.count)
    )

    return PendingPurchaseFulfillmentResult(
      createdLicenses: activationUpdatedCreatedLicenses,
      updatedExistingLicenses: updatedExistingLicenses,
      serverResponse: serverResponse,
      fulfillmentPolicy: fulfillmentPolicy
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
    fulfillmentPolicy: PaddleFulfillmentPolicy = PaddleFulfillmentPolicy(
      mode: .individualSeats,
      purchasedQuantity: 1
    ),
    seatNumber: Int = 1
  ) -> LicenseRecord {
    let transaction = purchase.payload.data
    let customer = transaction?.customer
    let item = transaction?.primaryItem

    let name = transaction?.customerName ?? ""
    let email = transaction?.customerEmail ?? ""
    let note = licenseNote(
      fulfillmentPolicy: fulfillmentPolicy,
      seatNumber: seatNumber
    )
    let productName = item?.product?.name ?? (
      fulfillmentPolicy.mode == .siteLicense ? "UpDock Pro Site License" : "UpDock Pro"
    )

    return LicenseRecord(
      serial: LicenseGenerator.makeSerial(type: .commercial),
      type: .commercial,
      product: productName,
      name: name,
      email: email,
      expiresAt: nil,
      notes: note,
      seatAllowance: seatAllowance(for: fulfillmentPolicy),
      seatsAssigned: 0,
      paddleCustomerID: transaction?.customerID ?? customer?.id ?? "",
      paddleTransactionID: purchase.transactionID,
      paddleEmail: email,
      paddleProductID: item?.product?.id ?? item?.price?.productID ?? "",
      paddlePriceID: item?.price?.id ?? "",
      paddleStatus: transaction?.status ?? "",
      fulfilledAt: Date(),
      fulfillmentArchiveStatus: .archived,
      fulfillmentArchiveCheckedAt: Date(),
      activationRegistryStatus: fulfillmentPolicy.mode == .siteLicense ? .unknown : .notRequired
    )
  }

  private func registerActivationRegistryIfNeeded(
    licenses: [LicenseRecord],
    settings: NetworkSettings
  ) async -> [LicenseRecord] {
    var registeredLicenses: [LicenseRecord] = []

    for license in licenses {
      guard license.seatAllowance != nil else {
        var updatedLicense = license
        updatedLicense.activationRegistryStatus = .notRequired
        registeredLicenses.append(updatedLicense)
        continue
      }

      do {
        registeredLicenses.append(
          try await ActivationRegistryService.shared.registerLicense(
            license,
            settings: settings
          )
        )
      } catch {
        var updatedLicense = license
        updatedLicense.activationRegistryStatus = .failed
        updatedLicense.activationRegistryCheckedAt = Date()
        updatedLicense.activationRegistryError = error.localizedDescription
        registeredLicenses.append(updatedLicense)
      }
    }

    return registeredLicenses
  }

  private func licenseNote(
    fulfillmentPolicy: PaddleFulfillmentPolicy,
    seatNumber: Int
  ) -> String {
    switch fulfillmentPolicy.mode {
    case .individualSeats:
      let seatNote = fulfillmentPolicy.purchasedQuantity > 1
        ? " Seat \(seatNumber) of \(fulfillmentPolicy.purchasedQuantity)."
        : ""

      return "Created from pending Paddle purchase.\(seatNote)"
    case .siteLicense:
      return "Created from pending Paddle site license purchase. Site license seat allowance: \(fulfillmentPolicy.purchasedQuantity)."
    }
  }

  private func seatAllowance(for fulfillmentPolicy: PaddleFulfillmentPolicy) -> Int? {
    switch fulfillmentPolicy.mode {
    case .individualSeats:
      return nil
    case .siteLicense:
      return fulfillmentPolicy.purchasedQuantity
    }
  }
}
