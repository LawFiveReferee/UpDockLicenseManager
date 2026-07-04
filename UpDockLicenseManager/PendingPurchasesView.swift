//
//  PendingPurchasesView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import SwiftUI

struct PendingPurchasesView: View {
  @Environment(\.dismiss) private var dismiss

  let existingLicenseForTransactionID: (String) -> LicenseRecord?
  let onFulfillPurchase: (LicenseRecord) -> Void

  @State private var networkSettings = NetworkSettings()
  @State private var purchases: [PendingPaddlePurchase] = []
  @State private var selectedPurchaseID: PendingPaddlePurchase.ID?

  @State private var isLoading = false
  @State private var fulfillingTransactionID: String?
  @State private var errorMessage: String?
  @State private var statusMessage: String?

  private var selectedPurchase: PendingPaddlePurchase? {
    purchases.first { $0.id == selectedPurchaseID }
  }

  private var isWorking: Bool {
    isLoading || fulfillingTransactionID != nil
  }

  var body: some View {
    NavigationSplitView {
      purchaseList
    } detail: {
      purchaseDetail
    }
    .frame(width: 1000, height: 680)
    .toolbar {
      ToolbarItemGroup {
        Menu {
          Section("Generate") {
            Button("Generate 1") {
              Task { await generateTestPurchases(count: 1) }
            }

            Button("Generate 5") {
              Task { await generateTestPurchases(count: 5) }
            }

            Button("Generate 10") {
              Task { await generateTestPurchases(count: 10) }
            }

            Button("Generate 100") {
              Task { await generateTestPurchases(count: 100) }
            }
          }

          Divider()

          Section("Clear Test Purchases") {
            Button("Clear Pending Tests") {
              Task { await clearPendingTests() }
            }

            Button("Clear Fulfilled Tests") {
              Task { await clearFulfilledTests() }
            }

            Button("Clear All Tests") {
              Task { await clearAllTests() }
            }
          }
        } label: {
          Label("Developer", systemImage: "hammer")
        }
        .disabled(isWorking)

        Button {
          Task { await refresh() }
        } label: {
          Label("Refresh", systemImage: "arrow.clockwise")
        }
        .disabled(isWorking)

        Button("Close") {
          dismiss()
        }
      }
    }
    .task {
      await refresh(selectFirstIfNeeded: true)
    }
  }

  private var purchaseList: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Pending Purchases")
        .font(.title2.bold())
        .padding(.horizontal)
        .padding(.top)

      if let errorMessage {
        Label(errorMessage, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.red)
          .padding(.horizontal)
      }

      if let statusMessage {
        Label(statusMessage, systemImage: "checkmark.circle")
          .foregroundStyle(.green)
          .padding(.horizontal)
      }

      if isLoading {
        ProgressView("Loading…")
          .padding(.horizontal)
      }

      List(selection: $selectedPurchaseID) {
        ForEach(purchases) { purchase in
          VStack(alignment: .leading, spacing: 5) {
            Text(purchase.payload.data?.customer?.email ?? "Unknown Customer")
              .font(.headline)

            Text(purchase.payload.data?.customer?.name ?? "—")
              .foregroundStyle(.secondary)

            Text(purchase.transactionID)
              .font(.system(.caption, design: .monospaced))
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
          .tag(purchase.id)
        }
      }
      .overlay {
        if purchases.isEmpty && !isLoading {
          ContentUnavailableView(
            "No Pending Purchases",
            systemImage: "tray",
            description: Text("Generate test purchases or wait for Paddle webhooks.")
          )
        }
      }
    }
    .frame(minWidth: 340)
  }

  private var purchaseDetail: some View {
    Group {
      if let selectedPurchase {
        PendingPurchaseDetailView(
          purchase: selectedPurchase,
          isFulfilling: fulfillingTransactionID == selectedPurchase.transactionID,
          statusMessage: statusMessage,
          onFulfillPurchase: { purchase in
            Task {
              await fulfillPurchase(purchase)
            }
          }
        )
      } else {
        ContentUnavailableView(
          "No Purchase Selected",
          systemImage: "creditcard",
          description: Text("Select a pending purchase to review it.")
        )
      }
    }
  }

  private func refresh(selectFirstIfNeeded: Bool = false) async {
    isLoading = true
    errorMessage = nil

    do {
      try await fetchPurchases(
        preferredSelectionID: selectedPurchaseID,
        selectFirstIfNeeded: selectFirstIfNeeded
      )
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  private func generateTestPurchases(count: Int) async {
    isLoading = true
    errorMessage = nil
    statusMessage = nil

    do {
      try await ServerService.shared.generateTestPurchases(
        settings: networkSettings,
        count: count
      )

      try await fetchPurchases(selectFirstIfNeeded: true)
      statusMessage = "Generated \(count) test purchase\(count == 1 ? "" : "s")."
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  private func clearPendingTests() async {
    isLoading = true
    errorMessage = nil
    statusMessage = nil

    do {
      try await ServerService.shared.clearPendingTestPurchases(
        settings: networkSettings
      )

      try await fetchPurchases(selectFirstIfNeeded: true)
      statusMessage = "Cleared pending test purchases."
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  private func clearFulfilledTests() async {
    isLoading = true
    errorMessage = nil
    statusMessage = nil

    do {
      try await ServerService.shared.clearFulfilledTestPurchases(
        settings: networkSettings
      )

      statusMessage = "Cleared fulfilled test purchases."
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  private func clearAllTests() async {
    isLoading = true
    errorMessage = nil
    statusMessage = nil

    do {
      try await ServerService.shared.clearAllTestPurchases(
        settings: networkSettings
      )

      try await fetchPurchases(selectFirstIfNeeded: true)
      statusMessage = "Cleared all test purchases."
    } catch {
      errorMessage = error.localizedDescription
    }

    isLoading = false
  }

  private func fulfillPurchase(_ purchase: PendingPaddlePurchase) async {
    fulfillingTransactionID = purchase.transactionID
    errorMessage = nil
    statusMessage = "Fulfilling \(purchase.payload.data?.customer?.email ?? purchase.transactionID)…"

    do {
      let nextSelectionID = preferredSelectionID(afterRemoving: purchase)
      let result = try await FulfillmentCoordinator.shared.fulfillPendingPurchase(
        purchase,
        settings: networkSettings,
        existingLicenseForTransactionID: existingLicenseForTransactionID
      )

      if result.didCreateLicense {
        onFulfillPurchase(result.license)
      }

      purchases.removeAll {
        $0.transactionID == purchase.transactionID
      }

      selectedPurchaseID = nextSelectionID
      try await fetchPurchases(
        preferredSelectionID: nextSelectionID,
        selectFirstIfNeeded: true
      )
      statusMessage = result.statusMessage
    } catch {
      errorMessage = error.localizedDescription
    }

    fulfillingTransactionID = nil
  }

  private func fetchPurchases(
    preferredSelectionID: PendingPaddlePurchase.ID? = nil,
    selectFirstIfNeeded: Bool = false
  ) async throws {
    let response = try await PendingPurchasesService.shared
      .fetchPendingPurchases(settings: networkSettings)

    purchases = response.items

    if let preferredSelectionID,
       purchases.contains(where: { $0.id == preferredSelectionID }) {
      selectedPurchaseID = preferredSelectionID
    } else if selectFirstIfNeeded || selectedPurchaseID == nil {
      selectedPurchaseID = purchases.first?.id
    } else if !purchases.contains(where: { $0.id == selectedPurchaseID }) {
      selectedPurchaseID = purchases.first?.id
    }
  }

  private func preferredSelectionID(
    afterRemoving purchase: PendingPaddlePurchase
  ) -> PendingPaddlePurchase.ID? {
    guard let index = purchases.firstIndex(where: { $0.id == purchase.id }) else {
      return selectedPurchaseID
    }

    let remainingPurchases = purchases.filter { $0.id != purchase.id }

    guard !remainingPurchases.isEmpty else {
      return nil
    }

    return remainingPurchases[min(index, remainingPurchases.count - 1)].id
  }
}

struct PendingPurchaseDetailView: View {
  let purchase: PendingPaddlePurchase
  let isFulfilling: Bool
  let statusMessage: String?
  let onFulfillPurchase: (PendingPaddlePurchase) -> Void

  private var transaction: PaddleTransactionData? {
    purchase.payload.data
  }

  private var customer: PaddleCustomerData? {
    transaction?.customer
  }

  private var item: PaddleTransactionItem? {
    transaction?.items?.first
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Purchase Review")
          .font(.largeTitle.bold())

        if isFulfilling {
          ProgressView("Fulfilling purchase…")
        } else if let statusMessage {
          Label(statusMessage, systemImage: "checkmark.circle")
            .foregroundStyle(.green)
        }

        detailCard("Customer") {
          row("Name", customer?.name ?? "—")
          row("Email", customer?.email ?? "—")
          row("Customer ID", transaction?.customerID ?? customer?.id ?? "—")
        }

        detailCard("Purchase") {
          row("Transaction ID", purchase.transactionID)
          row("Status", transaction?.status ?? "—")
          row("Received", purchase.receivedAt)
          row("Event Type", purchase.eventType)
        }

        detailCard("Product") {
          row("Product", item?.product?.name ?? "—")
          row("Product ID", item?.product?.id ?? "—")
          row("Price ID", item?.price?.id ?? "—")
        }

        detailCard("Fulfillment Preview") {
          row("License Type", "Commercial")
          row("Expiration", "None")
          row("Result", "Create license and archive transaction")
        }

        HStack {
          Button("Preview License") {
          }
          .disabled(true)

          Button("Fulfill Purchase") {
            onFulfillPurchase(purchase)
          }
          .buttonStyle(.borderedProminent)
          .disabled(isFulfilling)
        }
      }
      .padding(24)
      .frame(maxWidth: 720, alignment: .leading)
    }
  }

  private func detailCard<Content: View>(
    _ title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)

      content()
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
  }

  private func row(_ label: String, _ value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(label)
        .foregroundStyle(.secondary)
        .frame(width: 140, alignment: .leading)

      Text(value.isEmpty ? "—" : value)
        .textSelection(.enabled)
    }
  }
}
