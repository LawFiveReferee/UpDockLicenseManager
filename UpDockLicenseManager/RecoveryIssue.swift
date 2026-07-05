import Foundation

enum RecoveryIssueSeverity: String, Codable, CaseIterable, Identifiable {
  case warning = "Warning"
  case failure = "Failure"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .warning: return "exclamationmark.triangle"
    case .failure: return "xmark.circle"
    }
  }
}

struct RecoveryIssue: Identifiable, Codable, Hashable {
  var id: UUID
  var severity: RecoveryIssueSeverity
  var title: String
  var detail: String
  var licenseID: UUID?
  var licenseSerial: String
  var customerEmail: String
  var paddleTransactionID: String

  init(
    id: UUID = UUID(),
    severity: RecoveryIssueSeverity,
    title: String,
    detail: String,
    license: LicenseRecord? = nil,
    paddleTransactionID: String = ""
  ) {
    self.id = id
    self.severity = severity
    self.title = title
    self.detail = detail
    self.licenseID = license?.id
    self.licenseSerial = license?.serial ?? ""
    self.customerEmail = license?.email ?? ""
    self.paddleTransactionID = paddleTransactionID.isEmpty
      ? license?.paddleTransactionID ?? ""
      : paddleTransactionID
  }
}
