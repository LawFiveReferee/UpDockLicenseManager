import Foundation
import Observation
import UniformTypeIdentifiers

@Observable
final class LicenseStore {
  var licenses: [LicenseRecord] = [] {
    didSet {
      save()
    }
  }

  private let fileURL: URL

  init() {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let folder = appSupport.appendingPathComponent("UpDock License Manager", isDirectory: true)

    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    self.fileURL = folder.appendingPathComponent("licenses.json")

    load()
  }

  func add(_ license: LicenseRecord) {
    licenses.insert(license, at: 0)
  }

  func importMissing(_ importedLicenses: [LicenseRecord]) -> [LicenseRecord] {
    let existingSerials = Set(licenses.map { $0.serial.lowercased() })
    let newLicenses = importedLicenses.filter {
      !existingSerials.contains($0.serial.lowercased())
    }

    licenses.insert(contentsOf: newLicenses, at: 0)

    return newLicenses
  }

  func delete(_ licensesToDelete: [LicenseRecord]) {
    let ids = Set(licensesToDelete.map(\.id))
    licenses.removeAll { ids.contains($0.id) }
  }

  func removeAllForDevelopment() -> Int {
    let removedCount = licenses.count
    licenses.removeAll()
    return removedCount
  }

  func exportJSON(to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(licenses)
    try data.write(to: url, options: [.atomic])
  }

  func exportCSV(to url: URL) throws {
    let csv = makeCSV()
    try csv.write(to: url, atomically: true, encoding: .utf8)
  }

  func licenseForPaddleTransactionID(_ transactionID: String) -> LicenseRecord? {
    licensesForPaddleTransactionID(transactionID).first
  }

  func licensesForPaddleTransactionID(_ transactionID: String) -> [LicenseRecord] {
    let trimmed = transactionID.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
      return []
    }

    return licenses.filter {
      $0.paddleTransactionID.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
    }
  }

  private func load() {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

    do {
      let data = try Data(contentsOf: fileURL)
      licenses = try JSONDecoder().decode([LicenseRecord].self, from: data)
    } catch {
      print("Failed to load licenses:", error)
    }
  }

  private func save() {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(licenses)
      try data.write(to: fileURL, options: [.atomic])
    } catch {
      print("Failed to save licenses:", error)
    }
  }

  private func makeCSV() -> String {
    var rows: [String] = []

    rows.append([
      "Serial",
      "Kind",
      "Product",
      "Name",
      "Email",
      "Issued At",
      "Expires At",
      "Seat Allowance",
      "Seats Assigned",
      "Email Delivery Status",
      "Email Delivery Last Action",
      "Email Delivery Error",
      "Activation Registry Status",
      "Activation Registry Checked At",
      "Activation Registry Error",
      "Notes"
    ].joined(separator: ","))

    for license in licenses {
      rows.append([
        csvEscape(license.serial),
        csvEscape(license.type.rawValue),
        csvEscape(license.product),
        csvEscape(license.name),
        csvEscape(license.email),
        csvEscape(license.issuedAt.formatted(.iso8601)),
        csvEscape(license.expiresAt?.formatted(.iso8601) ?? ""),
        csvEscape(license.seatAllowance.map(String.init) ?? ""),
        csvEscape(String(license.seatsAssigned)),
        csvEscape(license.emailDeliveryStatus.rawValue),
        csvEscape(license.emailDeliveryAttemptedAt?.formatted(.iso8601) ?? ""),
        csvEscape(license.emailDeliveryError),
        csvEscape(license.activationRegistryStatus.rawValue),
        csvEscape(license.activationRegistryCheckedAt?.formatted(.iso8601) ?? ""),
        csvEscape(license.activationRegistryError),
        csvEscape(license.notes)
      ].joined(separator: ","))
    }

    return rows.joined(separator: "\n")
  }

  private func csvEscape(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  var totalCount: Int {
    licenses.count
  }

  var needsEmailCount: Int {
    licenses.filter(\.needsEmailDelivery).count
  }

  var activeCount: Int {
    licenses.filter { $0.status == .active }.count
  }

  var activeBetaCount: Int {
    licenses.filter { $0.status == .active && $0.type == .beta }.count
  }

  var activeTrialCount: Int {
    licenses.filter { $0.status == .active && $0.type == .trial }.count
  }

  var activeCommercialCount: Int {
    licenses.filter { $0.status == .active && $0.type == .commercial }.count
  }

  var expiringSoonCount: Int {
    licenses.filter { $0.status == .expiringSoon }.count
  }

  var expiredCount: Int {
    licenses.filter { $0.status == .expired }.count
  }

  var revokedCount: Int {
    licenses.filter { $0.status == .revoked }.count
  }

  func count(for filter: LicenseSidebarFilter) -> Int {
    switch filter {
    case .all:
      return totalCount
    case .needsEmail:
      return needsEmailCount
    case .active:
      return activeCount
    case .activeBeta:
      return activeBetaCount
    case .activeTrial:
      return activeTrialCount
    case .activeCommercial:
      return activeCommercialCount
    case .expiringSoon:
      return expiringSoonCount
    case .expired:
      return expiredCount
    case .revoked:
      return revokedCount
    }
  }

  func exportLicenseFile(for record: LicenseRecord, to url: URL) throws {
    let signedFile = try LicenseService.signedLicenseFile(from: record)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601

    let data = try encoder.encode(signedFile)
    try data.write(to: url, options: .atomic)

    let writtenData = try Data(contentsOf: url)

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    let writtenFile = try decoder.decode(LicenseFile.self, from: writtenData)

    let isValid = try LicenseService.verifyLicenseFile(writtenFile)

    guard isValid else {
      throw LicenseExportError.verificationFailed
    }
  }

  func exportLicenseFileToFolder(for record: LicenseRecord, folderURL: URL) throws -> URL {
    let fileName = LicenseFileNameService.suggestedLicenseFileName(for: record)
    let fileURL = folderURL.appendingPathComponent(fileName)

    try exportLicenseFile(for: record, to: fileURL)

    return fileURL
  }

  func exportLicenseFileToTemporaryFolder(for record: LicenseRecord) throws -> URL {
    let folderURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("UpDock License Exports", isDirectory: true)

    try FileManager.default.createDirectory(
      at: folderURL,
      withIntermediateDirectories: true
    )

    let fileName = LicenseFileNameService.suggestedLicenseFileName(for: record)
    let fileURL = folderURL.appendingPathComponent(fileName)

    try exportLicenseFile(for: record, to: fileURL)

    return fileURL
  }
}

enum LicenseExportError: Error, LocalizedError {
  case verificationFailed

  var errorDescription: String? {
    switch self {
    case .verificationFailed:
      return "The license file was written, but signature verification failed."
    }
  }
}
