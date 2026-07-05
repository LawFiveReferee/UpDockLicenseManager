import SwiftUI

struct RecoveryReportView: View {
  @Environment(\.dismiss) private var dismiss

  let issues: [RecoveryIssue]
  let onSelectLicense: (UUID) -> Void
  let onExport: () -> Void

  @State private var searchText = ""

  private var issueGroups: [RecoveryIssueGroup] {
    RecoveryIssueGroup.makeGroups(from: issues)
  }

  private var filteredGroups: [RecoveryIssueGroup] {
    let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedSearch.isEmpty else {
      return issueGroups
    }

    return issueGroups.compactMap { group in
      let matchingIssues = group.issues.filter { issue in
        [
          issue.severity.rawValue,
          issue.title,
          issue.detail,
          issue.licenseSerial,
          issue.customerEmail,
          issue.paddleTransactionID
        ]
          .joined(separator: " ")
          .localizedCaseInsensitiveContains(trimmedSearch)
      }

      if matchingIssues.isEmpty && !group.searchText.localizedCaseInsensitiveContains(trimmedSearch) {
        return nil
      }

      return group.withIssues(matchingIssues.isEmpty ? group.issues : matchingIssues)
    }
  }

  private var failureCount: Int {
    issues.filter { $0.severity == .failure }.count
  }

  private var warningCount: Int {
    issues.filter { $0.severity == .warning }.count
  }

  private var transactionCount: Int {
    Set(
      issues
        .map { $0.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    ).count
  }

  private var customerCount: Int {
    Set(
      issues
        .map { $0.customerEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .filter { !$0.isEmpty }
    ).count
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        summary

        List(filteredGroups) { group in
          RecoveryIssueGroupRow(group: group) {
            if let licenseID = group.primaryLicenseID {
              onSelectLicense(licenseID)
              dismiss()
            }
          }
        }
        .overlay {
          if filteredGroups.isEmpty {
            ContentUnavailableView(
              "No Recovery Issues",
              systemImage: "checkmark.seal",
              description: Text(searchText.isEmpty ? "No mismatches were found." : "No issues match your search.")
            )
          }
        }
      }
      .navigationTitle("Recovery Report")
      .searchable(text: $searchText, prompt: "Search recovery report")
      .toolbar {
        ToolbarItemGroup {
          Button {
            onExport()
          } label: {
            Label("Export CSV", systemImage: "square.and.arrow.up")
          }
          .disabled(issues.isEmpty)

          Button("Close") {
            dismiss()
          }
        }
      }
    }
    .frame(width: 900, height: 640)
  }

  private var summary: some View {
    HStack(spacing: 16) {
      summaryMetric(
        title: "Failures",
        value: failureCount,
        systemImage: "xmark.circle",
        color: .red
      )

      summaryMetric(
        title: "Warnings",
        value: warningCount,
        systemImage: "exclamationmark.triangle",
        color: .orange
      )

      summaryMetric(
        title: "Total Issues",
        value: issues.count,
        systemImage: "wrench.and.screwdriver",
        color: .secondary
      )

      summaryMetric(
        title: "Transactions",
        value: transactionCount,
        systemImage: "creditcard",
        color: .secondary
      )

      summaryMetric(
        title: "Customers",
        value: customerCount,
        systemImage: "person.2",
        color: .secondary
      )
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.regularMaterial)
  }

  private func summaryMetric(
    title: String,
    value: Int,
    systemImage: String,
    color: Color
  ) -> some View {
    Label {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("\(value)")
          .font(.title3.bold())
          .monospacedDigit()
      }
    } icon: {
      Image(systemName: systemImage)
        .foregroundStyle(color)
    }
  }

}

struct RecoveryIssueGroup: Identifiable {
  var id: String { groupKey }
  var issues: [RecoveryIssue]

  static func makeGroups(from issues: [RecoveryIssue]) -> [RecoveryIssueGroup] {
    let grouped = Dictionary(grouping: issues) { issue in
      let transactionID = issue.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines)
      let licenseID = issue.licenseID?.uuidString ?? ""
      let email = issue.customerEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

      if !transactionID.isEmpty {
        return "transaction:\(transactionID)"
      }

      if !licenseID.isEmpty {
        return "license:\(licenseID)"
      }

      if !email.isEmpty {
        return "customer:\(email)"
      }

      return "issue:\(issue.id.uuidString)"
    }

    return grouped.values.map { groupIssues in
      RecoveryIssueGroup(issues: groupIssues)
    }
    .sorted { first, second in
      if first.severity != second.severity {
        return first.severity == .failure
      }

      return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
    }
  }

  var groupKey: String {
    let first = issues.first
    let transactionID = first?.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let licenseID = first?.licenseID?.uuidString ?? ""
    let email = first?.customerEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

    if !transactionID.isEmpty {
      return "transaction:\(transactionID)"
    }

    if !licenseID.isEmpty {
      return "license:\(licenseID)"
    }

    if !email.isEmpty {
      return "customer:\(email)"
    }

    return "issue:\(first?.id.uuidString ?? UUID().uuidString)"
  }

  var title: String {
    if !paddleTransactionID.isEmpty {
      return paddleTransactionID
    }

    if !customerEmail.isEmpty {
      return customerEmail
    }

    if !licenseSerial.isEmpty {
      return licenseSerial
    }

    return "Unlinked Recovery Item"
  }

  var subtitle: String {
    let values = [
      customerEmail.isEmpty ? nil : customerEmail,
      licenseSerial.isEmpty ? nil : licenseSerial
    ].compactMap { $0 }

    return values.isEmpty ? "No linked customer or license" : values.joined(separator: "  •  ")
  }

  var severity: RecoveryIssueSeverity {
    issues.contains { $0.severity == .failure } ? .failure : .warning
  }

  var failureCount: Int {
    issues.filter { $0.severity == .failure }.count
  }

  var warningCount: Int {
    issues.filter { $0.severity == .warning }.count
  }

  var primaryLicenseID: UUID? {
    issues.compactMap(\.licenseID).first
  }

  var paddleTransactionID: String {
    issues.first?.paddleTransactionID ?? ""
  }

  var licenseSerial: String {
    issues.first?.licenseSerial ?? ""
  }

  var customerEmail: String {
    issues.first?.customerEmail ?? ""
  }

  var searchText: String {
    [
      title,
      subtitle,
      severity.rawValue,
      issues.map(\.title).joined(separator: " "),
      issues.map(\.detail).joined(separator: " ")
    ].joined(separator: " ")
  }

  func withIssues(_ issues: [RecoveryIssue]) -> RecoveryIssueGroup {
    RecoveryIssueGroup(issues: issues)
  }
}

struct RecoveryIssueGroupRow: View {
  let group: RecoveryIssueGroup
  let onSelect: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: group.severity.symbol)
        .frame(width: 24)
        .foregroundStyle(group.severity == .failure ? .red : .orange)

      VStack(alignment: .leading, spacing: 10) {
        HStack(alignment: .firstTextBaseline) {
          Text(group.title)
            .font(.headline)

          Spacer()

          Text(summaryText)
            .font(.caption)
            .foregroundStyle(group.severity == .failure ? .red : .orange)
        }

        Text(group.subtitle)
          .font(.caption)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)

        VStack(alignment: .leading, spacing: 6) {
          ForEach(group.issues) { issue in
            HStack(alignment: .top, spacing: 8) {
              Image(systemName: issue.severity.symbol)
                .frame(width: 18)
                .foregroundStyle(issue.severity == .failure ? .red : .orange)

              VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                  .font(.subheadline.bold())

                Text(issue.detail)
                  .font(.callout)
                  .foregroundStyle(.secondary)
              }
            }
          }
        }

        if group.primaryLicenseID != nil {
          Button("Show License") {
            onSelect()
          }
          .buttonStyle(.link)
        }
      }
    }
    .padding(.vertical, 5)
  }

  private var summaryText: String {
    let parts = [
      group.failureCount == 0 ? nil : "\(group.failureCount) failure\(group.failureCount == 1 ? "" : "s")",
      group.warningCount == 0 ? nil : "\(group.warningCount) warning\(group.warningCount == 1 ? "" : "s")"
    ].compactMap { $0 }

    return parts.joined(separator: ", ")
  }
}
