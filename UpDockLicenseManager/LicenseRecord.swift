import Foundation

enum UpDockLicenseType: String, Codable, CaseIterable, Identifiable {
  case beta = "Beta"
  case trial = "Trial"
  case commercial = "Commercial"

  var id: String { rawValue }
}

enum LicenseStatus: String, Codable, CaseIterable, Identifiable {
  case active = "Active"
  case expiringSoon = "Expiring Soon"
  case expired = "Expired"
  case revoked = "Revoked"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .active: return "🟢"
    case .expiringSoon: return "🟡"
    case .expired: return "🔴"
    case .revoked: return "⚫"
    }
  }
}

enum FulfillmentArchiveStatus: String, Codable, CaseIterable, Identifiable {
  case unknown = "Unknown"
  case pending = "Pending"
  case archived = "Archived"
  case notFound = "Not Found"

  var id: String { rawValue }
}

enum EmailDeliveryStatus: String, Codable, CaseIterable, Identifiable {
  case notPrepared = "Not Prepared"
  case draftPrepared = "Draft Prepared"
  case failed = "Failed"

  var id: String { rawValue }
}

struct LicenseRecord: Identifiable, Codable, Hashable {
  var id: UUID
  var serial: String
  var type: UpDockLicenseType
  var product: String
  var name: String
  var email: String
  var issuedAt: Date
  var expiresAt: Date?
  var notes: String
  var isRevoked: Bool

  // Paddle metadata
  var paddleCustomerID: String
  var paddleTransactionID: String
  var paddleEmail: String
  var paddleProductID: String
  var paddlePriceID: String
  var paddleStatus: String
  var fulfilledAt: Date?
  var fulfillmentArchiveStatus: FulfillmentArchiveStatus
  var fulfillmentArchiveCheckedAt: Date?
  var emailDeliveryStatus: EmailDeliveryStatus
  var emailDeliveryAttemptedAt: Date?
  var emailDeliveryError: String

  init(
    id: UUID = UUID(),
    serial: String,
    type: UpDockLicenseType,
    product: String = "UpDock Pro",
    name: String = "",
    email: String = "",
    issuedAt: Date = Date(),
    expiresAt: Date? = nil,
    notes: String = "",
    isRevoked: Bool = false,
    paddleCustomerID: String = "",
    paddleTransactionID: String = "",
    paddleEmail: String = "",
    paddleProductID: String = "",
    paddlePriceID: String = "",
    paddleStatus: String = "",
    fulfilledAt: Date? = nil,
    fulfillmentArchiveStatus: FulfillmentArchiveStatus = .unknown,
    fulfillmentArchiveCheckedAt: Date? = nil,
    emailDeliveryStatus: EmailDeliveryStatus = .notPrepared,
    emailDeliveryAttemptedAt: Date? = nil,
    emailDeliveryError: String = ""
  ) {
    self.id = id
    self.serial = serial
    self.type = type
    self.product = product
    self.name = name
    self.email = email
    self.issuedAt = issuedAt
    self.expiresAt = expiresAt
    self.notes = notes
    self.isRevoked = isRevoked
    self.paddleCustomerID = paddleCustomerID
    self.paddleTransactionID = paddleTransactionID
    self.paddleEmail = paddleEmail
    self.paddleProductID = paddleProductID
    self.paddlePriceID = paddlePriceID
    self.paddleStatus = paddleStatus
    self.fulfilledAt = fulfilledAt
    self.fulfillmentArchiveStatus = fulfillmentArchiveStatus
    self.fulfillmentArchiveCheckedAt = fulfillmentArchiveCheckedAt
    self.emailDeliveryStatus = emailDeliveryStatus
    self.emailDeliveryAttemptedAt = emailDeliveryAttemptedAt
    self.emailDeliveryError = emailDeliveryError
  }

  var status: LicenseStatus {
    if isRevoked { return .revoked }

    guard let expiresAt else { return .active }

    let now = Date()

    if expiresAt < now {
      return .expired
    }

    let daysRemaining = Calendar.current.dateComponents([.day], from: now, to: expiresAt).day ?? 0

    if daysRemaining <= 14 {
      return .expiringSoon
    }

    return .active
  }

  var needsEmailDelivery: Bool {
    !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && emailDeliveryStatus != .draftPrepared
      && !isRevoked
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case serial
    case type
    case product
    case name
    case email
    case issuedAt
    case expiresAt
    case notes
    case isRevoked
    case paddleCustomerID
    case paddleTransactionID
    case paddleEmail
    case paddleProductID
    case paddlePriceID
    case paddleStatus
    case fulfilledAt
    case fulfillmentArchiveStatus
    case fulfillmentArchiveCheckedAt
    case emailDeliveryStatus
    case emailDeliveryAttemptedAt
    case emailDeliveryError
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(UUID.self, forKey: .id)
    serial = try container.decode(String.self, forKey: .serial)
    type = try container.decode(UpDockLicenseType.self, forKey: .type)
    product = try container.decode(String.self, forKey: .product)
    name = try container.decode(String.self, forKey: .name)
    email = try container.decode(String.self, forKey: .email)
    issuedAt = try container.decode(Date.self, forKey: .issuedAt)
    expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
    notes = try container.decode(String.self, forKey: .notes)
    isRevoked = try container.decode(Bool.self, forKey: .isRevoked)

    paddleCustomerID = try container.decodeIfPresent(String.self, forKey: .paddleCustomerID) ?? ""
    paddleTransactionID = try container.decodeIfPresent(String.self, forKey: .paddleTransactionID) ?? ""
    paddleEmail = try container.decodeIfPresent(String.self, forKey: .paddleEmail) ?? ""
    paddleProductID = try container.decodeIfPresent(String.self, forKey: .paddleProductID) ?? ""
    paddlePriceID = try container.decodeIfPresent(String.self, forKey: .paddlePriceID) ?? ""
    paddleStatus = try container.decodeIfPresent(String.self, forKey: .paddleStatus) ?? ""
    fulfilledAt = try container.decodeIfPresent(Date.self, forKey: .fulfilledAt)
    fulfillmentArchiveStatus = try container.decodeIfPresent(
      FulfillmentArchiveStatus.self,
      forKey: .fulfillmentArchiveStatus
    ) ?? .unknown
    fulfillmentArchiveCheckedAt = try container.decodeIfPresent(
      Date.self,
      forKey: .fulfillmentArchiveCheckedAt
    )
    emailDeliveryStatus = try container.decodeIfPresent(
      EmailDeliveryStatus.self,
      forKey: .emailDeliveryStatus
    ) ?? .notPrepared
    emailDeliveryAttemptedAt = try container.decodeIfPresent(
      Date.self,
      forKey: .emailDeliveryAttemptedAt
    )
    emailDeliveryError = try container.decodeIfPresent(
      String.self,
      forKey: .emailDeliveryError
    ) ?? ""
  }
}
