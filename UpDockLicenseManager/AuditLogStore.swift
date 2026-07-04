import Foundation
import Observation

@Observable
final class AuditLogStore {
  var events: [AuditEvent] = [] {
    didSet {
      save()
    }
  }

  private let fileURL: URL

  init() {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let folder = appSupport.appendingPathComponent("UpDock License Manager", isDirectory: true)

    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

    self.fileURL = folder.appendingPathComponent("audit-log.json")

    load()
  }

  func record(_ event: AuditEvent) {
    events.insert(event, at: 0)
  }

  func events(for license: LicenseRecord) -> [AuditEvent] {
    events.filter {
      $0.licenseID == license.id
        || (!license.serial.isEmpty && $0.licenseSerial == license.serial)
        || (!license.paddleTransactionID.isEmpty && $0.paddleTransactionID == license.paddleTransactionID)
    }
  }

  func exportJSON(to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(events)
    try data.write(to: url, options: [.atomic])
  }

  private func load() {
    guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

    do {
      let data = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      events = try decoder.decode([AuditEvent].self, from: data)
    } catch {
      print("Failed to load audit log:", error)
    }
  }

  private func save() {
    do {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      encoder.dateEncodingStrategy = .iso8601
      let data = try encoder.encode(events)
      try data.write(to: fileURL, options: [.atomic])
    } catch {
      print("Failed to save audit log:", error)
    }
  }
}
