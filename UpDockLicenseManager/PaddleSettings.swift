//
//  PaddleSettings.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/2/26.
//
import Foundation
import Observation

@Observable
final class PaddleSettings {

  enum Environment: String, CaseIterable, Codable, Identifiable {
    case sandbox = "Sandbox"
    case production = "Production"

    var id: String { rawValue }
  }

  var environment: Environment {
    didSet { save() }
  }

  var defaultProductID: String {
    didSet { save() }
  }

  var defaultPriceID: String {
    didSet { save() }
  }

  private let defaults = UserDefaults.standard

  init() {
    environment = Environment(
      rawValue: defaults.string(forKey: "paddle.environment") ?? "Sandbox"
    ) ?? .sandbox

    defaultProductID = defaults.string(forKey: "paddle.product") ?? ""
    defaultPriceID = defaults.string(forKey: "paddle.price") ?? ""
  }

  private func save() {
    defaults.set(environment.rawValue, forKey: "paddle.environment")
    defaults.set(defaultProductID, forKey: "paddle.product")
    defaults.set(defaultPriceID, forKey: "paddle.price")
  }
}

@Observable
final class PaddleFulfillmentPolicyStore {
  var siteLicenseProductIDs: String {
    didSet { save() }
  }

  var siteLicensePriceIDs: String {
    didSet { save() }
  }

  private let defaults = UserDefaults.standard

  init() {
    siteLicenseProductIDs = defaults.string(forKey: "paddle.policy.siteLicenseProductIDs") ?? ""
    siteLicensePriceIDs = defaults.string(forKey: "paddle.policy.siteLicensePriceIDs") ?? ""
  }

  func policy(for purchase: PendingPaddlePurchase) -> PaddleFulfillmentPolicy {
    let item = purchase.payload.data?.primaryItem
    let productID = item?.product?.id ?? item?.price?.productID ?? ""
    let priceID = item?.price?.id ?? ""
    let siteProductIDs = normalizedIDSet(from: siteLicenseProductIDs)
    let sitePriceIDs = normalizedIDSet(from: siteLicensePriceIDs)
    let isSiteLicense = siteProductIDs.contains(productID.lowercased())
      || sitePriceIDs.contains(priceID.lowercased())

    return PaddleFulfillmentPolicy(
      mode: isSiteLicense ? .siteLicense : .individualSeats,
      purchasedQuantity: purchase.licenseQuantity
    )
  }

  private func save() {
    defaults.set(siteLicenseProductIDs, forKey: "paddle.policy.siteLicenseProductIDs")
    defaults.set(siteLicensePriceIDs, forKey: "paddle.policy.siteLicensePriceIDs")
  }

  private func normalizedIDSet(from text: String) -> Set<String> {
    let separators = CharacterSet(charactersIn: ", \n\t")

    return Set(
      text
        .components(separatedBy: separators)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .filter { !$0.isEmpty }
    )
  }
}

struct PaddleFulfillmentPolicy {
  enum Mode {
    case individualSeats
    case siteLicense
  }

  var mode: Mode
  var purchasedQuantity: Int

  var generatedLicenseCount: Int {
    switch mode {
    case .individualSeats:
      return max(purchasedQuantity, 1)
    case .siteLicense:
      return 1
    }
  }

  var displayName: String {
    switch mode {
    case .individualSeats:
      return "Individual Seats"
    case .siteLicense:
      return "Site License"
    }
  }

  var licenseTypeLabel: String {
    switch mode {
    case .individualSeats:
      return "Commercial"
    case .siteLicense:
      return "Commercial Site License"
    }
  }
}
