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
  func importOptedIn(from licenses: [LicenseRecord]) -> Int {
    let existingContacts = contacts
    var contactsByEmail = Dictionary(uniqueKeysWithValues: contacts.map { ($0.id, $0) })

    for license in licenses where license.paddleMarketingConsent {
      let email = license.email.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !email.isEmpty else {
        continue
      }

      let key = email.lowercased()
      let existing = contactsByEmail[key]
      let latestPurchaseAt = [existing?.latestPurchaseAt, license.fulfilledAt, license.issuedAt]
        .compactMap { $0 }
        .max()

      contactsByEmail[key] = MarketingContact(
        email: email,
        name: preferred(existing?.name, license.name),
        paddleCustomerID: preferred(existing?.paddleCustomerID, license.paddleCustomerID),
        latestPurchaseAt: latestPurchaseAt
      )
    }

    contacts = contactsByEmail.values.sorted {
      $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending
    }

    return contacts.filter { !existingContacts.contains($0) }.count
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

  private func preferred(_ existing: String?, _ replacement: String) -> String {
    let existingValue = existing?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let replacementValue = replacement.trimmingCharacters(in: .whitespacesAndNewlines)

    return existingValue.isEmpty ? replacementValue : existingValue
  }
}

struct MarketingContact: Identifiable, Codable, Hashable {
  var email: String
  var name: String
  var paddleCustomerID: String
  var latestPurchaseAt: Date?

  var id: String {
    email.lowercased()
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
}
