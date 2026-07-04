//
//  LicenseDetailView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseDetailView: View {
  @State private var editableLicense: LicenseRecord
  @State private var originalLicense: LicenseRecord
  @State private var isCheckingFulfillmentArchive = false
  @State private var isPreparingEmailDelivery = false
  @State private var fulfillmentArchiveError: String?

  let onSave: (LicenseRecord) -> Void
  let onCopySerial: () -> Void
  let onRevoke: () -> Void
  let onPrepareEmailDelivery: (LicenseRecord) throws -> LicenseRecord
  let onRefreshFulfillmentArchive: (LicenseRecord) async throws -> LicenseRecord

  init(
    license: LicenseRecord,
    onSave: @escaping (LicenseRecord) -> Void,
    onCopySerial: @escaping () -> Void,
    onRevoke: @escaping () -> Void,
    onPrepareEmailDelivery: @escaping (LicenseRecord) throws -> LicenseRecord,
    onRefreshFulfillmentArchive: @escaping (LicenseRecord) async throws -> LicenseRecord
  ) {
    self._editableLicense = State(initialValue: license)
    self._originalLicense = State(initialValue: license)
    self.onSave = onSave
    self.onCopySerial = onCopySerial
    self.onRevoke = onRevoke
    self.onPrepareEmailDelivery = onPrepareEmailDelivery
    self.onRefreshFulfillmentArchive = onRefreshFulfillmentArchive
  }

  private var hasUnsavedChanges: Bool {
    editableLicense != originalLicense
  }

  private var hasPaddleTransaction: Bool {
    !editableLicense.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        card {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("License")
                .font(.title2.bold())

              Spacer()

              Text("\(editableLicense.status.symbol) \(editableLicense.status.rawValue)")
                .font(.headline)
            }

            Text(editableLicense.serial)
              .font(.system(.title3, design: .monospaced))
              .textSelection(.enabled)

            HStack {
              Button("Copy Serial") {
                onCopySerial()
              }

              Button(hasUnsavedChanges ? "Save Changes" : "Saved") {
                saveChanges()
              }
              .buttonStyle(.borderedProminent)
              .disabled(!hasUnsavedChanges)

              Button("Revert") {
                editableLicense = originalLicense
              }
              .disabled(!hasUnsavedChanges)

              Button("Revoke", role: .destructive) {
                onRevoke()
              }
              .disabled(editableLicense.isRevoked)
            }
          }
        }

        if hasPaddleTransaction {
          card {
            VStack(alignment: .leading, spacing: 14) {
              Text("Web Fulfillment")
                .font(.headline)

              Label(fulfillmentArchiveTitle, systemImage: fulfillmentArchiveSymbol)
                .foregroundStyle(fulfillmentArchiveStyle)

              detailRow("Transaction ID", editableLicense.paddleTransactionID)

              if let checkedAt = editableLicense.fulfillmentArchiveCheckedAt {
                detailRow("Last Checked", checkedAt.formatted(date: .abbreviated, time: .shortened))
              } else {
                detailRow("Last Checked", "Never")
              }

              if let fulfillmentArchiveError {
                Label(fulfillmentArchiveError, systemImage: "exclamationmark.triangle")
                  .foregroundStyle(.red)
              }

              Button {
                Task {
                  await refreshFulfillmentArchive()
                }
              } label: {
                if isCheckingFulfillmentArchive {
                  ProgressView()
                } else {
                  Label("Refresh Status", systemImage: "arrow.clockwise")
                }
              }
              .disabled(isCheckingFulfillmentArchive)
            }
          }
        }

        card {
          VStack(alignment: .leading, spacing: 14) {
            Text("Email Delivery")
              .font(.headline)

            Label(emailDeliveryTitle, systemImage: emailDeliverySymbol)
              .foregroundStyle(emailDeliveryStyle)

            detailRow("Recipient", editableLicense.email)

            if let attemptedAt = editableLicense.emailDeliveryAttemptedAt {
              detailRow("Last Attempt", attemptedAt.formatted(date: .abbreviated, time: .shortened))
            } else {
              detailRow("Last Attempt", "Never")
            }

            if !editableLicense.emailDeliveryError.isEmpty {
              Label(editableLicense.emailDeliveryError, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
            }

            Button {
              prepareEmailDelivery()
            } label: {
              if isPreparingEmailDelivery {
                ProgressView()
              } else {
                Label(emailDeliveryButtonTitle, systemImage: "envelope")
              }
            }
            .disabled(isPreparingEmailDelivery || editableLicense.email.isEmpty)
          }
        }

        card {
          VStack(alignment: .leading, spacing: 14) {
            Text("Customer / Tester")
              .font(.headline)

            TextField("Name", text: $editableLicense.name)
              .textFieldStyle(.roundedBorder)

            TextField("Email", text: $editableLicense.email)
              .textFieldStyle(.roundedBorder)
          }
        }

        card {
          VStack(alignment: .leading, spacing: 14) {
            Text("License Details")
              .font(.headline)

            Picker("Type", selection: $editableLicense.type) {
              ForEach(UpDockLicenseType.allCases) { type in
                Text(type.rawValue).tag(type)
              }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 320)

            DatePicker(
              "Issued",
              selection: $editableLicense.issuedAt,
              displayedComponents: [.date]
            )

            if editableLicense.type == .beta || editableLicense.type == .trial {
              DatePicker(
                "Expires",
                selection: Binding(
                  get: {
                    editableLicense.expiresAt ?? Date()
                  },
                  set: {
                    editableLicense.expiresAt = $0
                  }
                ),
                displayedComponents: [.date]
              )
            }
          }
        }

        card {
          VStack(alignment: .leading, spacing: 14) {
            Text("Notes")
              .font(.headline)

            TextField("Notes", text: $editableLicense.notes, axis: .vertical)
              .textFieldStyle(.roundedBorder)
              .lineLimit(4...8)
          }
        }
      }
      .padding(24)
    }
    .id(originalLicense.id)
  }

  private var fulfillmentArchiveTitle: String {
    switch editableLicense.fulfillmentArchiveStatus {
    case .unknown:
      return "Not verified on website"
    case .pending:
      return "Still pending on website"
    case .archived:
      return "In fulfilled directory"
    case .notFound:
      return "Not found on website"
    }
  }

  private var fulfillmentArchiveSymbol: String {
    switch editableLicense.fulfillmentArchiveStatus {
    case .unknown:
      return "questionmark.circle"
    case .pending:
      return "clock"
    case .archived:
      return "checkmark.seal"
    case .notFound:
      return "exclamationmark.triangle"
    }
  }

  private var fulfillmentArchiveStyle: AnyShapeStyle {
    switch editableLicense.fulfillmentArchiveStatus {
    case .unknown:
      return AnyShapeStyle(.secondary)
    case .pending:
      return AnyShapeStyle(.orange)
    case .archived:
      return AnyShapeStyle(.green)
    case .notFound:
      return AnyShapeStyle(.red)
    }
  }

  private var emailDeliveryTitle: String {
    switch editableLicense.emailDeliveryStatus {
    case .notPrepared:
      return "No email draft prepared"
    case .draftPrepared:
      return "Mail draft prepared"
    case .failed:
      return "Email draft failed"
    }
  }

  private var emailDeliverySymbol: String {
    switch editableLicense.emailDeliveryStatus {
    case .notPrepared:
      return "envelope"
    case .draftPrepared:
      return "envelope.badge"
    case .failed:
      return "exclamationmark.triangle"
    }
  }

  private var emailDeliveryStyle: AnyShapeStyle {
    switch editableLicense.emailDeliveryStatus {
    case .notPrepared:
      return AnyShapeStyle(.secondary)
    case .draftPrepared:
      return AnyShapeStyle(.green)
    case .failed:
      return AnyShapeStyle(.red)
    }
  }

  private var emailDeliveryButtonTitle: String {
    switch editableLicense.emailDeliveryStatus {
    case .notPrepared:
      return "Prepare Email"
    case .draftPrepared, .failed:
      return "Retry Email"
    }
  }

  private func refreshFulfillmentArchive() async {
    isCheckingFulfillmentArchive = true
    fulfillmentArchiveError = nil

    do {
      let updatedLicense = try await onRefreshFulfillmentArchive(originalLicense)

      editableLicense.fulfillmentArchiveStatus = updatedLicense.fulfillmentArchiveStatus
      editableLicense.fulfillmentArchiveCheckedAt = updatedLicense.fulfillmentArchiveCheckedAt
      editableLicense.fulfilledAt = updatedLicense.fulfilledAt
      originalLicense = updatedLicense
    } catch {
      fulfillmentArchiveError = error.localizedDescription
    }

    isCheckingFulfillmentArchive = false
  }

  private func prepareEmailDelivery() {
    isPreparingEmailDelivery = true

    do {
      let updatedLicense = try onPrepareEmailDelivery(originalLicense)

      editableLicense.emailDeliveryStatus = updatedLicense.emailDeliveryStatus
      editableLicense.emailDeliveryAttemptedAt = updatedLicense.emailDeliveryAttemptedAt
      editableLicense.emailDeliveryError = updatedLicense.emailDeliveryError
      originalLicense = updatedLicense
    } catch {
      editableLicense.emailDeliveryStatus = .failed
      editableLicense.emailDeliveryAttemptedAt = Date()
      editableLicense.emailDeliveryError = error.localizedDescription
      onSave(editableLicense)
      originalLicense = editableLicense
    }

    isPreparingEmailDelivery = false
  }

  private func saveChanges() {
    onSave(editableLicense)
    originalLicense = editableLicense
  }

  private func detailRow(_ label: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(label)
        .foregroundStyle(.secondary)
        .frame(width: 120, alignment: .leading)

      Text(value.isEmpty ? "—" : value)
        .textSelection(.enabled)
    }
  }

  private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      content()
    }
    .padding(18)
    .frame(maxWidth: 650, alignment: .leading)
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }
}
