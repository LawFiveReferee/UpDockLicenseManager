//
//  LicenseListView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseListView: View {
  let licenses: [LicenseRecord]
  @Binding var selectedLicense: LicenseRecord?
  let searchText: String

  var body: some View {
    List(selection: $selectedLicense) {
      ForEach(licenses) { license in
        LicenseRowView(
          license: license,
          relatedPaddleLicenseCount: relatedPaddleLicenseCount(for: license)
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

  private func relatedPaddleLicenseCount(for license: LicenseRecord) -> Int {
    let transactionID = license.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !transactionID.isEmpty else {
      return 1
    }

    return max(
      licenses.filter {
        $0.paddleTransactionID.localizedCaseInsensitiveCompare(transactionID) == .orderedSame
      }.count,
      1
    )
  }
}

struct LicenseRowView: View {
  let license: LicenseRecord
  let relatedPaddleLicenseCount: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack {
        Text(license.status.symbol)

        Text(primaryTitle)
          .font(.headline)

        Spacer()

        if relatedPaddleLicenseCount > 1 {
          Text("\(relatedPaddleLicenseCount) seats")
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
