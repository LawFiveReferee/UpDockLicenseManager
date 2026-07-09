//
//  LicenseDistributionService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import AppKit
import Foundation

enum LicenseDistributionService {
  static func exportLicenseFile(
    record: LicenseRecord,
    store: LicenseStore,
    to url: URL
  ) throws {
    try store.exportLicenseFile(for: record, to: url)
  }

  static func exportAndRevealLicenseFile(
    record: LicenseRecord,
    store: LicenseStore,
    folderURL: URL
  ) throws {
    let exportedURL = try store.exportLicenseFileToFolder(
      for: record,
      folderURL: folderURL
    )

    NSWorkspace.shared.activateFileViewerSelecting([exportedURL])
  }

  static func exportAndEmailLicenseFile(
    record: LicenseRecord,
    store: LicenseStore,
    emailSettings: EmailSettings = EmailSettings()
  ) throws -> LicenseRecord {
    let exportedURL = try store.exportLicenseFileToTemporaryFolder(
      for: record
    )

    let subject = LicenseEmailService.makeEmailSubject(for: record)
    let body = LicenseEmailService.makeEmailBody(
      for: record,
      settings: emailSettings
    )

    try LicenseEmailService.openMailDraft(
      to: record.email,
      subject: subject,
      body: body,
      attachmentURL: exportedURL
    )

    var updatedRecord = record
    updatedRecord.emailDeliveryStatus = .draftPrepared
    updatedRecord.emailDeliveryAttemptedAt = Date()
    updatedRecord.emailDeliveryError = ""

    return updatedRecord
  }
}
