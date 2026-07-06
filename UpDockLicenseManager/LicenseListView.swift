//
//  LicenseListView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation
import SwiftUI

struct LicenseListView: View {
  let licenses: [LicenseRecord]
  let allLicenses: [LicenseRecord]
  @Binding var selectedLicense: LicenseRecord?
  let searchText: String

  var body: some View {
    List(selection: $selectedLicense) {
      ForEach(licenses) { license in
        LicenseRowView(
          license: license,
          seatBadgeText: LicenseSeatBadgeContext.make(
            for: license,
            in: allLicenses
          ).badgeText
        )
        .tag(license)
      }
    }
    .navigationTitle("Licenses")
    .overlay {
      if licenses.isEmpty {
        ContentUnavailableView(
          "No Licenses",
          systemImage: "key",
          description: Text(searchText.isEmpty ? "Create a new license to get started." : "No licenses match your search.")
        )
      }
    }
  }

}

struct LicenseRowView: View {
  let license: LicenseRecord
  let seatBadgeText: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack {
        Text(license.status.symbol)

        Text(primaryTitle)
          .font(.headline)

        Spacer()

        if let seatBadgeText {
          Text(seatBadgeText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.quaternary, in: Capsule())
        }

        Text(license.type.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Text(license.serial)
        .font(.system(.caption, design: .monospaced))
        .foregroundStyle(.secondary)

      if !license.email.isEmpty {
        Text(license.email)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }

  private var primaryTitle: String {
    if !license.name.isEmpty {
      return license.name
    }

    if !license.email.isEmpty {
      return license.email
    }

    return "Unassigned License"
  }
}

struct LicenseSeatBadgeContext {
  var badgeText: String?
  var count: Int

  static func make(for license: LicenseRecord, in allLicenses: [LicenseRecord]) -> LicenseSeatBadgeContext {
    let relatedLicenses = relatedPaddleLicenses(for: license, in: allLicenses)

    if relatedLicenses.count > 1 {
      let seatNumber = explicitSeatNumber(for: license) ?? inferredSeatNumber(
        for: license,
        in: relatedLicenses
      )

      return LicenseSeatBadgeContext(
        badgeText: "Seat \(seatNumber) of \(relatedLicenses.count)",
        count: relatedLicenses.count
      )
    }

    if isSiteLicense(license) {
      return LicenseSeatBadgeContext(
        badgeText: "Site License",
        count: 1
      )
    }

    return LicenseSeatBadgeContext(
      badgeText: nil,
      count: 1
    )
  }

  private static func relatedPaddleLicenses(
    for license: LicenseRecord,
    in allLicenses: [LicenseRecord]
  ) -> [LicenseRecord] {
    let transactionID = license.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !transactionID.isEmpty else {
      return [license]
    }

    let relatedLicenses = allLicenses.filter {
      $0.paddleTransactionID.localizedCaseInsensitiveCompare(transactionID) == .orderedSame
    }

    return relatedLicenses.isEmpty ? [license] : relatedLicenses
  }

  private static func explicitSeatNumber(for license: LicenseRecord) -> Int? {
    let notes = license.notes as NSString
    let pattern = #"Seat\s+(\d+)\s+of\s+(\d+)"#

    guard let expression = try? NSRegularExpression(pattern: pattern) else {
      return nil
    }

    let range = NSRange(location: 0, length: notes.length)

    guard
      let match = expression.firstMatch(in: license.notes, range: range),
      match.numberOfRanges >= 2
    else {
      return nil
    }

    return Int(notes.substring(with: match.range(at: 1)))
  }

  private static func inferredSeatNumber(
    for license: LicenseRecord,
    in relatedLicenses: [LicenseRecord]
  ) -> Int {
    let sortedLicenses = relatedLicenses.sorted { first, second in
      if first.issuedAt != second.issuedAt {
        return first.issuedAt < second.issuedAt
      }

      return first.serial.localizedCaseInsensitiveCompare(second.serial) == .orderedAscending
    }

    guard let index = sortedLicenses.firstIndex(where: { $0.id == license.id }) else {
      return 1
    }

    return index + 1
  }

  private static func isSiteLicense(_ license: LicenseRecord) -> Bool {
    let searchable = [
      license.product,
      license.notes
    ]
      .joined(separator: " ")
      .lowercased()

    return searchable.contains("site license") || searchable.contains("site-license")
  }
}
