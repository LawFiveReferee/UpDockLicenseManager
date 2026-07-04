import Foundation

enum AuditEventKind: String, Codable, CaseIterable, Identifiable {
  case licenseCreated = "License Created"
  case licenseUpdated = "License Updated"
  case licenseDuplicated = "License Duplicated"
  case licenseDeleted = "License Deleted"
  case licenseRestored = "License Restored"
  case licenseRevoked = "License Revoked"
  case paddleFulfilled = "Paddle Fulfilled"
  case fulfillmentChecked = "Fulfillment Checked"
  case emailDraftPrepared = "Email Draft Prepared"
  case emailDraftFailed = "Email Draft Failed"
  case licenseExported = "License Exported"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .licenseCreated: return "plus"
    case .licenseUpdated: return "pencil"
    case .licenseDuplicated: return "plus.square.on.square"
    case .licenseDeleted: return "trash"
    case .licenseRestored: return "arrow.uturn.backward"
    case .licenseRevoked: return "xmark.seal"
    case .paddleFulfilled: return "checkmark.seal"
    case .fulfillmentChecked: return "arrow.clockwise"
    case .emailDraftPrepared: return "envelope.badge"
    case .emailDraftFailed: return "exclamationmark.triangle"
    case .licenseExported: return "square.and.arrow.up"
    }
  }
}

struct AuditEvent: Identifiable, Codable, Hashable {
  var id: UUID
  var createdAt: Date
  var kind: AuditEventKind
  var message: String
  var licenseID: UUID?
  var licenseSerial: String
  var customerName: String
  var customerEmail: String
  var paddleTransactionID: String

  init(
    id: UUID = UUID(),
    createdAt: Date = Date(),
    kind: AuditEventKind,
    message: String,
    license: LicenseRecord? = nil,
    paddleTransactionID: String = ""
  ) {
    self.id = id
    self.createdAt = createdAt
    self.kind = kind
    self.message = message
    self.licenseID = license?.id
    self.licenseSerial = license?.serial ?? ""
    self.customerName = license?.name ?? ""
    self.customerEmail = license?.email ?? ""
    self.paddleTransactionID = paddleTransactionID.isEmpty
      ? license?.paddleTransactionID ?? ""
      : paddleTransactionID
  }
}
