//
//  LicenseSecurityService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation
import CryptoKit

enum LicenseSigningService {

  static func generateKeyPair() -> Curve25519.Signing.PrivateKey {
    Curve25519.Signing.PrivateKey()
  }

  static func publicKey(from privateKey: Curve25519.Signing.PrivateKey)
  -> Curve25519.Signing.PublicKey
  {
    privateKey.publicKey
  }

  static func sign(
    data: Data,
    privateKey: Curve25519.Signing.PrivateKey
  ) throws -> Data {

    try privateKey.signature(for: data)
  }

  static func verify(
    signature: Data,
    data: Data,
    publicKey: Curve25519.Signing.PublicKey
  ) -> Bool {

    publicKey.isValidSignature(signature, for: data)
  }

  static func canonicalLicenseData(_ license: UpDockLicense) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    if license.formatVersion < UpDockLicense.currentFormatVersion {
      return try encoder.encode(LegacyPortableLicense(license: license))
    }

    return try encoder.encode(license)
  }
}

private struct LegacyPortableLicense: Encodable {
  var formatVersion: Int
  var serial: String
  var type: UpDockLicenseType
  var product: String
  var name: String
  var email: String
  var issuedAt: Date
  var expiresAt: Date?
  var signature: String?

  init(license: UpDockLicense) {
    formatVersion = license.formatVersion
    serial = license.serial
    type = license.type
    product = license.product
    name = license.name
    email = license.email
    issuedAt = license.issuedAt
    expiresAt = license.expiresAt
    signature = license.signature
  }
}
