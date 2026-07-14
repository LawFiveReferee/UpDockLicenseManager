//
//  UpDockLicense.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation

struct UpDockLicense: Codable, Hashable {
  static let currentFormatVersion = 2
  static let updockProBundleID = "com.stockly.updockpro"
  static let updockProEdition = "pro"
  static let defaultSeatAllowance = 3

  var formatVersion: Int
  var serial: String
  var type: UpDockLicenseType
  var product: String
  var bundleID: String
  var edition: String
  var licenseKind: String
  var customerID: String
  var seatAllowance: Int
  var name: String
  var email: String
  var issuedAt: Date
  var expiresAt: Date?
  var signature: String?

  init(
    formatVersion: Int = UpDockLicense.currentFormatVersion,
    serial: String,
    type: UpDockLicenseType,
    product: String = "UpDock Pro",
    bundleID: String = UpDockLicense.updockProBundleID,
    edition: String = UpDockLicense.updockProEdition,
    licenseKind: String? = nil,
    customerID: String,
    seatAllowance: Int = UpDockLicense.defaultSeatAllowance,
    name: String,
    email: String,
    issuedAt: Date,
    expiresAt: Date?,
    signature: String? = nil
  ) {
    self.formatVersion = formatVersion
    self.serial = serial
    self.type = type
    self.product = product
    self.bundleID = bundleID
    self.edition = edition
    self.licenseKind = licenseKind ?? type.portableLicenseKind
    self.customerID = customerID
    self.seatAllowance = seatAllowance
    self.name = name
    self.email = email
    self.issuedAt = issuedAt
    self.expiresAt = expiresAt
    self.signature = signature
  }

  private enum CodingKeys: String, CodingKey {
    case formatVersion
    case serial
    case type
    case product
    case bundleID
    case edition
    case licenseKind
    case customerID
    case seatAllowance
    case name
    case email
    case issuedAt
    case expiresAt
    case signature
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    formatVersion = try container.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
    serial = try container.decode(String.self, forKey: .serial)
    type = try container.decode(UpDockLicenseType.self, forKey: .type)
    product = try container.decodeIfPresent(String.self, forKey: .product) ?? "UpDock Pro"
    bundleID = try container.decodeIfPresent(String.self, forKey: .bundleID) ?? UpDockLicense.updockProBundleID
    edition = try container.decodeIfPresent(String.self, forKey: .edition) ?? UpDockLicense.updockProEdition
    licenseKind = try container.decodeIfPresent(String.self, forKey: .licenseKind) ?? type.portableLicenseKind
    customerID = try container.decodeIfPresent(String.self, forKey: .customerID) ?? serial
    seatAllowance = try container.decodeIfPresent(Int.self, forKey: .seatAllowance) ?? UpDockLicense.defaultSeatAllowance
    name = try container.decode(String.self, forKey: .name)
    email = try container.decode(String.self, forKey: .email)
    issuedAt = try container.decode(Date.self, forKey: .issuedAt)
    expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    signature = try container.decodeIfPresent(String.self, forKey: .signature)
  }
}

extension UpDockLicense {
  init(record: LicenseRecord) {
    self.init(
      serial: record.serial,
      type: record.type,
      product: record.product,
      customerID: record.id.uuidString,
      name: record.name,
      email: record.email,
      issuedAt: record.issuedAt,
      expiresAt: record.expiresAt,
      signature: nil
    )
  }
}

extension UpDockLicenseType {
  var portableLicenseKind: String {
    switch self {
    case .beta:
      return "beta"
    case .trial:
      return "trial"
    case .commercial:
      return "paid"
    }
  }
}
