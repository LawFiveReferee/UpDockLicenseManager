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
  @State private var selectedPurchaseIDs: Set<PendingPaddlePurchase.ID> = []

  @State private var isLoading = false
  @State private var fulfillingTransactionID: String?
  @State private var batchProgress: BatchFulfillmentProgress?
  @State private var errorMessage: String?
  @State private var statusMessage: String?
  @State private var webhookLogEntries: [WebhookLogEntry] = []
  @State private var showingWebhookLog = false

  private var selectedPurchases: [PendingPaddlePurchase] {
    purchases.filter { selectedPurchaseIDs.contains($0.id) }
  }

  private var selectedPurchase: PendingPaddlePurchase? {
    selectedPurchases.count == 1 ? selectedPurchases.first : nil
  }

  private var isWorking: Bool {
    isLoading || fulfillingTransactionID != nil || batchProgress != nil
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

          Divider()

          Section("Diagnostics") {
            Button("Check Webhook Log") {
              Task { await checkWebhookLog() }
            }
          }
        } label: {
          Label("Developer", systemImage: "hammer")
        }
        .disabled(isWorking)

        Button {
          Task { await fulfillSelectedPurchases() }
        } label: {
          Label("Fulfill Selected", systemImage: "checkmark.seal")
        }
        .disabled(isWorking || selectedPurchaseIDs.isEmpty)

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
    .sheet(isPresented: $showingWebhookLog) {
      WebhookLogView(entries: webhookLogEntries)
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

      if let batchProgress {
        VStack(alignment: .leading, spacing: 6) {
          ProgressView(
            value: Double(batchProgress.completedCount),
            total: Double(batchProgress.totalCount)
          )

          Text(batchProgress.statusText)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
      } else if let statusMessage {
        Label(statusMessage, systemImage: "checkmark.circle")
          .foregroundStyle(.green)
          .padding(.horizontal)
      }

      if isLoading {
        ProgressView("Loading…")
          .padding(.horizontal)
      }

      if selectedPurchaseIDs.count > 1 {
        Text("\(selectedPurchaseIDs.count) selected")
          .font(.caption)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
      }

      List(selection: $selectedPurchaseIDs) {
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
      if selectedPurchases.count > 1 {
        BatchFulfillmentDetailView(
          selectedCount: selectedPurchases.count,
          progress: batchProgress,
          onFulfillSelected: {
            Task {
              await fulfillSelectedPurchases()
            }
          }
        )
      } else if let selectedPurchase {
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
          description: Text("Select one purchase to review it, or select multiple purchases to fulfill a batch.")
        )
      }
    }
  }

  private func refresh(selectFirstIfNeeded: Bool = false) async {
    isLoading = true
    errorMessage = nil

    do {
      try await fetchPurchases(
        preferredSelectionIDs: selectedPurchaseIDs,
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

  private func checkWebhookLog() async {
    isLoading = true
    errorMessage = nil
    statusMessage = nil

    do {
      let response = try await ServerService.shared.fetchWebhookLog(settings: networkSettings)
      webhookLogEntries = response.entries
      showingWebhookLog = true
      statusMessage = response.entries.isEmpty
        ? "Webhook log is empty."
        : "Loaded \(response.entries.count) webhook log entr\(response.entries.count == 1 ? "y" : "ies")."
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
      let nextSelectionIDs = preferredSelectionIDs(afterRemoving: [purchase])
      let result = try await FulfillmentCoordinator.shared.fulfillPendingPurchase(
        purchase,
        settings: networkSettings,
        existingLicenseForTransactionID: existingLicenseForTransactionID
      )

      if result.didCreateLicense {
        onFulfillPurchase(result.license)
      }

      removePurchases([purchase])
      selectedPurchaseIDs = nextSelectionIDs

      try await fetchPurchases(
        preferredSelectionIDs: nextSelectionIDs,
        selectFirstIfNeeded: true
      )
      statusMessage = result.statusMessage
    } catch {
      errorMessage = error.localizedDescription
    }

    fulfillingTransactionID = nil
  }

  private func fulfillSelectedPurchases() async {
    let purchasesToFulfill = selectedPurchases

    guard !purchasesToFulfill.isEmpty else {
      return
    }

    batchProgress = BatchFulfillmentProgress(
      completedCount: 0,
      totalCount: purchasesToFulfill.count,
      currentLabel: nil
    )
    errorMessage = nil
    statusMessage = nil

    var createdCount = 0
    var existingCount = 0
    var completedPurchases: [PendingPaddlePurchase] = []

    for purchase in purchasesToFulfill {
      fulfillingTransactionID = purchase.transactionID
      batchProgress?.currentLabel = purchase.payload.data?.customer?.email ?? purchase.transactionID

      do {
        let result = try await FulfillmentCoordinator.shared.fulfillPendingPurchase(
          purchase,
          settings: networkSettings,
          existingLicenseForTransactionID: existingLicenseForTransactionID
        )

        if result.didCreateLicense {
          createdCount += 1
          onFulfillPurchase(result.license)
        } else {
          existingCount += 1
        }

        completedPurchases.append(purchase)
        removePurchases([purchase])
        batchProgress?.completedCount = completedPurchases.count
      } catch {
        errorMessage = "Stopped after \(completedPurchases.count) of \(purchasesToFulfill.count): \(error.localizedDescription)"
        break
      }
    }

    fulfillingTransactionID = nil
    selectedPurchaseIDs.subtract(completedPurchases.map(\.id))

    do {
      try await fetchPurchases(
        preferredSelectionIDs: selectedPurchaseIDs,
        selectFirstIfNeeded: true
      )
    } catch {
      errorMessage = error.localizedDescription
    }

    if errorMessage == nil {
      statusMessage = batchStatusMessage(
        createdCount: createdCount,
        existingCount: existingCount
      )
    }

    batchProgress = nil
  }

  private func fetchPurchases(
    preferredSelectionIDs: Set<PendingPaddlePurchase.ID> = [],
    selectFirstIfNeeded: Bool = false
  ) async throws {
    let response = try await PendingPurchasesService.shared
      .fetchPendingPurchases(settings: networkSettings)
    let availableIDs = Set(response.items.map(\.id))
    let retainedSelection = selectedPurchaseIDs.union(preferredSelectionIDs)
      .filter { availableIDs.contains($0) }

    purchases = response.items

    if !retainedSelection.isEmpty {
      selectedPurchaseIDs = retainedSelection
    } else if selectFirstIfNeeded, let firstID = purchases.first?.id {
      selectedPurchaseIDs = [firstID]
    } else {
      selectedPurchaseIDs = []
    }
  }

  private func preferredSelectionIDs(
    afterRemoving removedPurchases: [PendingPaddlePurchase]
  ) -> Set<PendingPaddlePurchase.ID> {
    let removedIDs = Set(removedPurchases.map(\.id))
    let remainingSelectedIDs = selectedPurchaseIDs.subtracting(removedIDs)

    if !remainingSelectedIDs.isEmpty {
      return remainingSelectedIDs
    }

    guard let firstRemovedIndex = purchases.firstIndex(where: { removedIDs.contains($0.id) }) else {
      return []
    }

    let remainingPurchases = purchases.filter { !removedIDs.contains($0.id) }

    guard !remainingPurchases.isEmpty else {
      return []
    }

    return [remainingPurchases[min(firstRemovedIndex, remainingPurchases.count - 1)].id]
  }

  private func removePurchases(_ removedPurchases: [PendingPaddlePurchase]) {
    let removedIDs = Set(removedPurchases.map(\.id))

    purchases.removeAll {
      removedIDs.contains($0.id)
    }
  }

  private func batchStatusMessage(
    createdCount: Int,
    existingCount: Int
  ) -> String {
    let totalCount = createdCount + existingCount

    if existingCount == 0 {
      return "Fulfilled \(totalCount) purchase\(totalCount == 1 ? "" : "s")."
    }

    return "Fulfilled \(totalCount) purchases: \(createdCount) new, \(existingCount) already existed."
  }
}

struct BatchFulfillmentProgress {
  var completedCount: Int
  var totalCount: Int
  var currentLabel: String?

  var statusText: String {
    if let currentLabel {
      return "Fulfilling \(completedCount + 1) of \(totalCount): \(currentLabel)"
    }

    return "Preparing \(totalCount) purchase\(totalCount == 1 ? "" : "s")…"
  }
}

struct BatchFulfillmentDetailView: View {
  let selectedCount: Int
  let progress: BatchFulfillmentProgress?
  let onFulfillSelected: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Batch Fulfillment")
          .font(.largeTitle.bold())

        detailCard("Selected Purchases") {
          row("Count", "\(selectedCount)")
          row("Mode", "Sequential fulfillment")
        }

        if let progress {
          detailCard("Progress") {
            ProgressView(
              value: Double(progress.completedCount),
              total: Double(progress.totalCount)
            )

            Text(progress.statusText)
              .foregroundStyle(.secondary)
          }
        }

        Button("Fulfill Selected Purchases") {
          onFulfillSelected()
        }
        .buttonStyle(.borderedProminent)
        .disabled(progress != nil)
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
    transaction?.primaryItem
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
          row("Product ID", item?.product?.id ?? item?.price?.productID ?? "—")
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

struct WebhookLogView: View {
  @Environment(\.dismiss) private var dismiss

  let entries: [WebhookLogEntry]

  var body: some View {
    NavigationStack {
      List {
        if entries.isEmpty {
          ContentUnavailableView(
            "No Webhook Events",
            systemImage: "tray",
            description: Text("Paddle has not reached the webhook since diagnostics were deployed.")
          )
        } else {
          ForEach(entries.reversed()) { entry in
            VStack(alignment: .leading, spacing: 8) {
              HStack(alignment: .firstTextBaseline) {
                Label(entry.status.capitalized, systemImage: symbol(for: entry.status))
                  .foregroundStyle(style(for: entry.status))

                Spacer()

                Text(entry.time)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                  .textSelection(.enabled)
              }

              Text(entry.message)
                .font(.headline)

              if let context = entry.context, !context.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                  ForEach(context.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack(alignment: .top) {
                      Text(key)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(width: 110, alignment: .leading)

                      Text(value)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                    }
                  }
                }
              }
            }
            .padding(.vertical, 6)
          }
        }
      }
      .navigationTitle("Webhook Log")
      .toolbar {
        ToolbarItem {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
    .frame(width: 720, height: 520)
  }

  private func symbol(for status: String) -> String {
    switch status.lowercased() {
    case "stored":
      return "checkmark.circle"
    case "ignored":
      return "minus.circle"
    default:
      return "exclamationmark.triangle"
    }
  }

  private func style(for status: String) -> Color {
    switch status.lowercased() {
    case "stored":
      return .green
    case "ignored":
      return .secondary
    default:
      return .red
    }
  }
}
