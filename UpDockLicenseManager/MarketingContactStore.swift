import Foundation
import Observation

@Observable
final class MarketingContactStore {
  var contacts: [MarketingContact] = [] {
    didSet {
      save()
    }
  }

  private let fileURL: URL

  init() {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let folder = appSupport.appendingPathComponent("UpDock License Manager", isDirectory: true)

    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    self.fileURL = folder.appendingPathComponent("marketing-contacts.json")

    load()
  }

  @discardableResult
  func importOptedIn(from licenses: [LicenseRecord]) -> MarketingContactImportResult {
    var contactsByID = Dictionary(uniqueKeysWithValues: contacts.map { ($0.id, $0) })
    var addedCount = 0
    var updatedContactIDs: Set<MarketingContact.ID> = []

    let optedInLicenses = licenses
      .filter(\.paddleMarketingConsent)
      .sorted { purchaseDate(for: $0) < purchaseDate(for: $1) }

    for license in optedInLicenses {
      let email = license.email.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !email.isEmpty else {
        continue
      }

      let key = MarketingContact.id(name: license.name, email: email)
      let existing = contactsByID[key]
      let purchaseAt = purchaseDate(for: license)
      let latestPurchaseAt = [existing?.latestPurchaseAt, license.fulfilledAt, license.issuedAt]
        .compactMap { $0 }
        .max()
      let shouldUseLicenseDetails = existing == nil || purchaseAt >= (existing?.latestPurchaseAt ?? .distantPast)

      let updatedContact = MarketingContact(
        email: email,
        name: shouldUseLicenseDetails ? preferred(license.name, existing?.name) : preferred(existing?.name, license.name),
        paddleCustomerID: shouldUseLicenseDetails ? preferred(license.paddleCustomerID, existing?.paddleCustomerID) : preferred(existing?.paddleCustomerID, license.paddleCustomerID),
        latestPurchaseAt: latestPurchaseAt
      )

      if let existing {
        if existing != updatedContact {
          updatedContactIDs.insert(key)
        }
      } else {
        addedCount += 1
      }

      contactsByID[key] = updatedContact
    }

    contacts = contactsByID.values.sorted {
      let emailComparison = $0.email.localizedCaseInsensitiveCompare($1.email)

      if emailComparison == .orderedSame {
        return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
      }

      return emailComparison == .orderedAscending
    }

    return MarketingContactImportResult(
      addedCount: addedCount,
      updatedCount: updatedContactIDs.count
    )
  }

  func delete(ids: Set<MarketingContact.ID>) {
    contacts.removeAll { ids.contains($0.id) }
  }

  func addSampleContact() {
    let timestamp = Int(Date().timeIntervalSince1970)
    let sample = MarketingContact(
      email: "sample-\(timestamp)@example.com",
      name: "Sample Marketing Contact",
      paddleCustomerID: "sample",
      latestPurchaseAt: Date()
    )

    var updatedContacts = contacts.filter { $0.id != sample.id }
    updatedContacts.append(sample)
    contacts = updatedContacts.sorted {
      $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending
    }
  }

  func reloadFromDisk() {
    load()
  }

  private func load() {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

    do {
      let data = try Data(contentsOf: fileURL)
      contacts = try JSONDecoder().decode([MarketingContact].self, from: data)
    } catch {
      print("Failed to load marketing contacts:", error)
    }
  }

  private func save() {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(contacts)
      try data.write(to: fileURL, options: [.atomic])
    } catch {
      print("Failed to save marketing contacts:", error)
    }
  }

  private func purchaseDate(for license: LicenseRecord) -> Date {
    license.fulfilledAt ?? license.issuedAt
  }

  private func preferred(_ primary: String?, _ fallback: String?) -> String {
    let primaryValue = primary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let fallbackValue = fallback?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    return primaryValue.isEmpty ? fallbackValue : primaryValue
  }
}

struct MarketingContactImportResult {
  var addedCount: Int
  var updatedCount: Int

  var changedCount: Int {
    addedCount + updatedCount
  }
}

struct MarketingContact: Identifiable, Codable, Hashable {
  var email: String
  var name: String
  var paddleCustomerID: String
  var latestPurchaseAt: Date?

  var id: String {
    Self.id(name: name, email: email)
  }

  static func id(name: String, email: String) -> String {
    "\(normalized(email))\t\(normalized(name))"
  }

  static func tsv(from contacts: [MarketingContact]) -> String {
    contacts
      .map { contact in
        "\(tabEscape(contact.name))\t\(tabEscape(contact.email))"
      }
      .joined(separator: "\n")
  }

  private static func tabEscape(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\t", with: " ")
      .replacingOccurrences(of: "\r", with: " ")
      .replacingOccurrences(of: "\n", with: " ")
  }

  private static func normalized(_ value: String) -> String {
    value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
  }
}
