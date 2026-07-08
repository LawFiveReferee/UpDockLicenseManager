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

  var clientSideToken: String {
    didSet { save() }
  }

  private let defaults = UserDefaults.standard

  init() {
    environment = Environment(
      rawValue: defaults.string(forKey: "paddle.environment") ?? "Sandbox"
    ) ?? .sandbox

    defaultProductID = defaults.string(forKey: "paddle.product") ?? ""
    defaultPriceID = defaults.string(forKey: "paddle.price") ?? ""
    clientSideToken = defaults.string(forKey: "paddle.clientSideToken") ?? ""
  }

  private func save() {
    defaults.set(environment.rawValue, forKey: "paddle.environment")
    defaults.set(defaultProductID, forKey: "paddle.product")
    defaults.set(defaultPriceID, forKey: "paddle.price")
    defaults.set(clientSideToken, forKey: "paddle.clientSideToken")
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
      .union(siteLicensePricingProductIDs())
    let sitePriceIDs = normalizedIDSet(from: siteLicensePriceIDs)
      .union(siteLicensePricingPriceIDs())
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

  private func siteLicensePricingPriceIDs() -> Set<String> {
    Set(
      SiteLicensePricingStore().tiers
        .map(\.priceID)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .filter { !$0.isEmpty }
    )
  }

  private func siteLicensePricingProductIDs() -> Set<String> {
    Set(
      SiteLicensePricingStore().tiers
        .map(\.productID)
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

struct SiteLicensePricingTier: Identifiable, Codable, Hashable {
  var id: UUID
  var minimumSeats: Int
  var maximumSeats: Int?
  var priceID: String
  var productID: String
  var discountPercent: Double
  var discountAmount: Double
  var unitPrice: Double

  init(
    id: UUID = UUID(),
    minimumSeats: Int,
    maximumSeats: Int?,
    priceID: String = "",
    productID: String = "",
    discountPercent: Double,
    discountAmount: Double,
    unitPrice: Double
  ) {
    self.id = id
    self.minimumSeats = minimumSeats
    self.maximumSeats = maximumSeats
    self.priceID = priceID
    self.productID = productID
    self.discountPercent = discountPercent
    self.discountAmount = discountAmount
    self.unitPrice = unitPrice
  }

  enum CodingKeys: String, CodingKey {
    case id
    case minimumSeats
    case maximumSeats
    case priceID
    case productID
    case discountPercent
    case discountAmount
    case unitPrice
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
    minimumSeats = try container.decode(Int.self, forKey: .minimumSeats)
    maximumSeats = try container.decodeIfPresent(Int.self, forKey: .maximumSeats)
    priceID = try container.decodeIfPresent(String.self, forKey: .priceID) ?? ""
    productID = try container.decodeIfPresent(String.self, forKey: .productID) ?? ""
    discountPercent = try container.decode(Double.self, forKey: .discountPercent)
    discountAmount = try container.decode(Double.self, forKey: .discountAmount)
    unitPrice = try container.decode(Double.self, forKey: .unitPrice)
  }

  var rangeLabel: String {
    if let maximumSeats {
      return "\(minimumSeats)-\(maximumSeats)"
    }

    return "\(minimumSeats)+"
  }

  var attributeRangeLabel: String {
    if let maximumSeats {
      return "\(minimumSeats)-\(maximumSeats)"
    }

    return "\(minimumSeats)-plus"
  }

  static var defaults: [SiteLicensePricingTier] {
    [
      SiteLicensePricingTier(
        minimumSeats: 1,
        maximumSeats: 4,
        discountPercent: 0,
        discountAmount: 0,
        unitPrice: 19.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 5,
        maximumSeats: 9,
        discountPercent: 5,
        discountAmount: 1,
        unitPrice: 18.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 10,
        maximumSeats: 14,
        discountPercent: 10,
        discountAmount: 2,
        unitPrice: 17.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 15,
        maximumSeats: 19,
        discountPercent: 15,
        discountAmount: 3,
        unitPrice: 16.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 20,
        maximumSeats: 24,
        discountPercent: 20,
        discountAmount: 4,
        unitPrice: 15.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 25,
        maximumSeats: 29,
        discountPercent: 25,
        discountAmount: 5,
        unitPrice: 14.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 30,
        maximumSeats: 34,
        discountPercent: 30,
        discountAmount: 6,
        unitPrice: 13.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 35,
        maximumSeats: 39,
        discountPercent: 35,
        discountAmount: 7,
        unitPrice: 12.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 40,
        maximumSeats: 44,
        discountPercent: 40,
        discountAmount: 8,
        unitPrice: 11.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 45,
        maximumSeats: 49,
        discountPercent: 45,
        discountAmount: 9,
        unitPrice: 10.99
      ),
      SiteLicensePricingTier(
        minimumSeats: 50,
        maximumSeats: nil,
        discountPercent: 50,
        discountAmount: 10,
        unitPrice: 9.99
      )
    ]
  }
}

@Observable
final class SiteLicensePricingStore {
  var tiers: [SiteLicensePricingTier] {
    didSet { save() }
  }

  private let defaults = UserDefaults.standard
  private let defaultsKey = "paddle.policy.siteLicensePricingTiers"

  init() {
    guard
      let data = defaults.data(forKey: defaultsKey),
      let tiers = try? JSONDecoder().decode([SiteLicensePricingTier].self, from: data)
    else {
      self.tiers = SiteLicensePricingTier.defaults
      return
    }

    self.tiers = tiers
  }

  func resetToDefaults() {
    tiers = SiteLicensePricingTier.defaults
  }

  func tier(for seatCount: Int) -> SiteLicensePricingTier? {
    let normalizedSeatCount = max(seatCount, 1)

    return tiers
      .sorted { first, second in
        first.minimumSeats < second.minimumSeats
      }
      .first { tier in
        guard normalizedSeatCount >= tier.minimumSeats else {
          return false
        }

        if let maximumSeats = tier.maximumSeats {
          return normalizedSeatCount <= maximumSeats
        }

        return true
      }
  }

  private func save() {
    guard let data = try? JSONEncoder().encode(tiers) else {
      return
    }

    defaults.set(data, forKey: defaultsKey)
  }
}
