import SwiftUI

struct AuditLogView: View {
  @Environment(\.dismiss) private var dismiss

  let events: [AuditEvent]
  let onExport: () -> Void

  @State private var searchText = ""

  private var filteredEvents: [AuditEvent] {
    let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedSearch.isEmpty else {
      return events
    }

    return events.filter { event in
      [
        event.kind.rawValue,
        event.message,
        event.licenseSerial,
        event.customerName,
        event.customerEmail,
        event.paddleTransactionID
      ]
        .joined(separator: " ")
        .localizedCaseInsensitiveContains(trimmedSearch)
    }
  }

  var body: some View {
    NavigationStack {
      List(filteredEvents) { event in
        AuditEventRow(event: event)
      }
      .overlay {
        if filteredEvents.isEmpty {
          ContentUnavailableView(
            "No Audit Events",
            systemImage: "clock.badge",
            description: Text(searchText.isEmpty ? "Workflow events will appear here." : "No events match your search.")
          )
        }
      }
      .navigationTitle("Audit Log")
      .searchable(text: $searchText, prompt: "Search audit log")
      .toolbar {
        ToolbarItemGroup {
          Button {
            onExport()
          } label: {
            Label("Export Audit Log", systemImage: "square.and.arrow.up")
          }
          .disabled(events.isEmpty)

          Button("Close") {
            dismiss()
          }
        }
      }
    }
    .frame(width: 860, height: 620)
  }
}

struct AuditEventRow: View {
  let event: AuditEvent

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: event.kind.symbol)
        .frame(width: 24)
        .foregroundStyle(.tint)

      VStack(alignment: .leading, spacing: 5) {
        HStack(alignment: .firstTextBaseline) {
          Text(event.kind.rawValue)
            .font(.headline)

          Spacer()

          Text(event.createdAt.formatted(date: .abbreviated, time: .shortened))
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }

        Text(event.message)
          .foregroundStyle(.primary)

        metadataText
          .font(.caption)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      }
    }
    .padding(.vertical, 5)
  }

  private var metadataText: Text {
    let values = [
      event.licenseSerial.isEmpty ? nil : event.licenseSerial,
      event.customerEmail.isEmpty ? nil : event.customerEmail,
      event.paddleTransactionID.isEmpty ? nil : event.paddleTransactionID
    ].compactMap { $0 }

    return Text(values.isEmpty ? "No linked record" : values.joined(separator: "  •  "))
  }
}
