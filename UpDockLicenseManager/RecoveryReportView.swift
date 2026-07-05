import SwiftUI

struct RecoveryReportView: View {
  @Environment(\.dismiss) private var dismiss

  let issues: [RecoveryIssue]
  let onSelectLicense: (UUID) -> Void

  @State private var searchText = ""

  private var filteredIssues: [RecoveryIssue] {
    let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedSearch.isEmpty else {
      return issues
    }

    return issues.filter { issue in
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
  }

  private var failureCount: Int {
    issues.filter { $0.severity == .failure }.count
  }

  private var warningCount: Int {
    issues.filter { $0.severity == .warning }.count
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        summary

        List(filteredIssues) { issue in
          RecoveryIssueRow(issue: issue) {
            if let licenseID = issue.licenseID {
              onSelectLicense(licenseID)
              dismiss()
            }
          }
        }
        .overlay {
          if filteredIssues.isEmpty {
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
        ToolbarItem {
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

struct RecoveryIssueRow: View {
  let issue: RecoveryIssue
  let onSelect: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: issue.severity.symbol)
        .frame(width: 24)
        .foregroundStyle(issue.severity == .failure ? .red : .orange)

      VStack(alignment: .leading, spacing: 5) {
        HStack(alignment: .firstTextBaseline) {
          Text(issue.title)
            .font(.headline)

          Spacer()

          Text(issue.severity.rawValue)
            .font(.caption)
            .foregroundStyle(issue.severity == .failure ? .red : .orange)
        }

        Text(issue.detail)

        metadataText
          .font(.caption)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)

        if issue.licenseID != nil {
          Button("Show License") {
            onSelect()
          }
          .buttonStyle(.link)
        }
      }
    }
    .padding(.vertical, 5)
  }

  private var metadataText: Text {
    let values = [
      issue.licenseSerial.isEmpty ? nil : issue.licenseSerial,
      issue.customerEmail.isEmpty ? nil : issue.customerEmail,
      issue.paddleTransactionID.isEmpty ? nil : issue.paddleTransactionID
    ].compactMap { $0 }

    return Text(values.isEmpty ? "No linked record" : values.joined(separator: "  •  "))
  }
}
