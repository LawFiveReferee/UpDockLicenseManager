//
//  PendingPurchasesView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation
import SwiftUI

struct EmailDraftPreparationResult {
  var preparedCount: Int
  var failedCount: Int
  var skippedCount: Int

  var statusText: String {
    var parts: [String] = []

    if preparedCount > 0 {
      parts.append("Prepared \(preparedCount) email draft\(preparedCount == 1 ? "" : "s")")
    }

    if skippedCount > 0 {
      parts.append("Skipped \(skippedCount) without customer email")
    }

    if failedCount > 0 {
      parts.append("\(failedCount) email draft\(failedCount == 1 ? "" : "s") failed")
    }

    return parts.joined(separator: ". ")
  }
}

struct PendingPurchasesView: View {
  @Environment(\.dismiss) private var dismiss

  let existingLicensesForTransactionID: (String) -> [LicenseRecord]
  let onFulfillPurchase: ([LicenseRecord], [LicenseRecord]) -> Void
  let onPrepareEmailDrafts: ([LicenseRecord]) -> EmailDraftPreparationResult

  @State private var networkSettings = NetworkSettings()
  @State private var purchases: [PendingPaddlePurchase] = []
  @State private var selectedPurchaseIDs: Set<PendingPaddlePurchase.ID> = []
  @AppStorage("prepareEmailDraftsAfterFulfillment") private var prepareEmailDraftsAfterFulfillment = false

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

            Text(purchase.paddleEnvironmentLabel)
              .font(.caption.bold())
              .foregroundStyle(environmentStyle(for: purchase))
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
          purchases: selectedPurchases,
          selectedCount: selectedPurchases.count,
          progress: batchProgress,
          prepareEmailDraftsAfterFulfillment: $prepareEmailDraftsAfterFulfillment,
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
          prepareEmailDraftsAfterFulfillment: $prepareEmailDraftsAfterFulfillment,
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
        existingLicensesForTransactionID: existingLicensesForTransactionID
      )

      onFulfillPurchase(result.createdLicenses, result.updatedExistingLicenses)
      let emailDraftResult = prepareEmailDraftsIfNeeded(for: result.createdLicenses)

      removePurchases([purchase])
      selectedPurchaseIDs = nextSelectionIDs

      try await fetchPurchases(
        preferredSelectionIDs: nextSelectionIDs,
        selectFirstIfNeeded: true
      )
      statusMessage = fulfillmentStatusMessage(
        result.statusMessage,
        emailDraftResult: emailDraftResult
      )
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

    var createdLicenseCount = 0
    var existingLicenseCount = 0
    var emailDraftPreparedCount = 0
    var emailDraftFailedCount = 0
    var emailDraftSkippedCount = 0
    var completedPurchases: [PendingPaddlePurchase] = []

    for purchase in purchasesToFulfill {
      fulfillingTransactionID = purchase.transactionID
      batchProgress?.currentLabel = purchase.payload.data?.customer?.email ?? purchase.transactionID

      do {
        let result = try await FulfillmentCoordinator.shared.fulfillPendingPurchase(
          purchase,
          settings: networkSettings,
          existingLicensesForTransactionID: existingLicensesForTransactionID
        )

        createdLicenseCount += result.createdLicenses.count
        existingLicenseCount += result.updatedExistingLicenses.count
        onFulfillPurchase(result.createdLicenses, result.updatedExistingLicenses)
        if let emailDraftResult = prepareEmailDraftsIfNeeded(for: result.createdLicenses) {
          emailDraftPreparedCount += emailDraftResult.preparedCount
          emailDraftFailedCount += emailDraftResult.failedCount
          emailDraftSkippedCount += emailDraftResult.skippedCount
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
        createdLicenseCount: createdLicenseCount,
        existingLicenseCount: existingLicenseCount,
        purchaseCount: completedPurchases.count,
        emailDraftResult: EmailDraftPreparationResult(
          preparedCount: emailDraftPreparedCount,
          failedCount: emailDraftFailedCount,
          skippedCount: emailDraftSkippedCount
        )
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

  private func prepareEmailDraftsIfNeeded(
    for licenses: [LicenseRecord]
  ) -> EmailDraftPreparationResult? {
    guard prepareEmailDraftsAfterFulfillment else {
      return nil
    }

    return onPrepareEmailDrafts(licenses)
  }

  private func fulfillmentStatusMessage(
    _ baseMessage: String,
    emailDraftResult: EmailDraftPreparationResult?
  ) -> String {
    guard let emailDraftResult,
          !emailDraftResult.statusText.isEmpty else {
      return baseMessage
    }

    return baseMessage + " " + emailDraftResult.statusText + "."
  }

  private func batchStatusMessage(
    createdLicenseCount: Int,
    existingLicenseCount: Int,
    purchaseCount: Int,
    emailDraftResult: EmailDraftPreparationResult
  ) -> String {
    let emailStatus = emailDraftResult.statusText.isEmpty
      ? ""
      : " " + emailDraftResult.statusText + "."

    if existingLicenseCount == 0 {
      return "Fulfilled \(purchaseCount) purchase\(purchaseCount == 1 ? "" : "s") and created \(createdLicenseCount) license\(createdLicenseCount == 1 ? "" : "s")." + emailStatus
    }

    return "Fulfilled \(purchaseCount) purchase\(purchaseCount == 1 ? "" : "s"): \(createdLicenseCount) new license\(createdLicenseCount == 1 ? "" : "s"), \(existingLicenseCount) existing." + emailStatus
  }

  private func environmentStyle(for purchase: PendingPaddlePurchase) -> AnyShapeStyle {
    switch purchase.paddleEnvironment?.lowercased() {
    case "production":
      return AnyShapeStyle(.green)
    case "sandbox":
      return AnyShapeStyle(.blue)
    case "unknown":
      return AnyShapeStyle(.orange)
    default:
      return AnyShapeStyle(.secondary)
    }
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
  let purchases: [PendingPaddlePurchase]
  let selectedCount: Int
  let progress: BatchFulfillmentProgress?
  @Binding var prepareEmailDraftsAfterFulfillment: Bool
  let onFulfillSelected: () -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        Text("Batch Fulfillment")
          .font(.largeTitle.bold())

        detailCard("Selected Purchases") {
          row("Count", "\(selectedCount)")
          row("Mode", "Sequential fulfillment")
          row("Environment", environmentSummary)
        }

        detailCard("Delivery") {
          Toggle(
            "Prepare email drafts after fulfillment",
            isOn: $prepareEmailDraftsAfterFulfillment
          )
          Text("Mail drafts are prepared for newly created licenses with customer email addresses.")
            .foregroundStyle(.secondary)
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

  private var environmentSummary: String {
    let labels = Dictionary(grouping: purchases, by: \.paddleEnvironmentLabel)
      .mapValues(\.count)

    return labels
      .sorted { $0.key < $1.key }
      .map { "\($0.key): \($0.value)" }
      .joined(separator: ", ")
  }
}

struct PendingPurchaseDetailView: View {
  let purchase: PendingPaddlePurchase
  let isFulfilling: Bool
  let statusMessage: String?
  @Binding var prepareEmailDraftsAfterFulfillment: Bool
  let onFulfillPurchase: (PendingPaddlePurchase) -> Void

  @State private var showingLicensePreview = false

  private var transaction: PaddleTransactionData? {
    purchase.payload.data
  }

  private var customer: PaddleCustomerData? {
    transaction?.customer
  }

  private var item: PaddleTransactionItem? {
    transaction?.primaryItem
  }

  private var licenseQuantity: Int {
    purchase.licenseQuantity
  }

  private var fulfillmentPolicy: PaddleFulfillmentPolicy {
    PaddleFulfillmentPolicyStore().policy(for: purchase)
  }

  private var siteLicensePricingTier: SiteLicensePricingTier? {
    guard fulfillmentPolicy.mode == .siteLicense else {
      return nil
    }

    return SiteLicensePricingStore().tier(for: fulfillmentPolicy.purchasedQuantity)
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
          row("Name", transaction?.customerName ?? "—")
          row("Email", transaction?.customerEmail ?? "—")
          row("Customer ID", transaction?.customerID ?? customer?.id ?? "—")
        }

        detailCard("Purchase") {
          row("Transaction ID", purchase.transactionID)
          row("Environment", purchase.paddleEnvironmentLabel)
          row("Status", transaction?.status ?? "—")
          row("Received", purchase.receivedAt)
          row("Event Type", purchase.eventType)
        }

        detailCard("Product") {
          row("Product", item?.product?.name ?? "—")
          row("Quantity", "\(licenseQuantity)")
          row("Product ID", item?.product?.id ?? item?.price?.productID ?? "—")
          row("Price ID", item?.price?.id ?? "—")
        }

        detailCard("Fulfillment Preview") {
          row("Policy", fulfillmentPolicy.displayName)
          row("License Type", fulfillmentPolicy.licenseTypeLabel)
          row("Licenses", "\(fulfillmentPolicy.generatedLicenseCount)")
          if fulfillmentPolicy.mode == .siteLicense {
            row("Seat Allowance", "\(fulfillmentPolicy.purchasedQuantity)")
          }
          row("Expiration", "None")
          row("Result", fulfillmentResultText)
          row("Email", prepareEmailDraftsAfterFulfillment ? "Prepare draft after fulfillment" : "Manual from license detail")
        }

        detailCard("Delivery") {
          Toggle(
            "Prepare email draft after fulfillment",
            isOn: $prepareEmailDraftsAfterFulfillment
          )
          Text("The app will create a signed license file and open an Apple Mail draft for the customer.")
            .foregroundStyle(.secondary)
        }

        if let siteLicensePricingTier {
          detailCard("Site License Pricing") {
            row("Range", siteLicensePricingTier.rangeLabel)
            row("Discount", percentText(siteLicensePricingTier.discountPercent))
            row("Discount Amount", moneyText(siteLicensePricingTier.discountAmount))
            row("Per Seat", moneyText(siteLicensePricingTier.unitPrice))
            row("Expected Total", moneyText(siteLicensePricingTier.unitPrice * Double(fulfillmentPolicy.purchasedQuantity)))
          }
        }

        HStack {
          Button("Preview License") {
            showingLicensePreview = true
          }
          .disabled(isFulfilling)

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
    .sheet(isPresented: $showingLicensePreview) {
      PendingLicensePreviewView(purchase: purchase)
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

  private var fulfillmentResultText: String {
    switch fulfillmentPolicy.mode {
    case .individualSeats:
      return "Create \(fulfillmentPolicy.generatedLicenseCount) license\(fulfillmentPolicy.generatedLicenseCount == 1 ? "" : "s") and archive transaction"
    case .siteLicense:
      return "Create one site license and archive transaction"
    }
  }

  private func moneyText(_ value: Double) -> String {
    String(format: "$%.2f", value)
  }

  private func percentText(_ value: Double) -> String {
    if value.rounded() == value {
      return "\(Int(value))%"
    }

    return "\(value)%"
  }
}

struct PendingLicensePreviewView: View {
  @Environment(\.dismiss) private var dismiss

  let purchase: PendingPaddlePurchase

  private var transaction: PaddleTransactionData? {
    purchase.payload.data
  }

  private var item: PaddleTransactionItem? {
    transaction?.primaryItem
  }

  private var licenseQuantity: Int {
    purchase.licenseQuantity
  }

  private var fulfillmentPolicy: PaddleFulfillmentPolicy {
    PaddleFulfillmentPolicyStore().policy(for: purchase)
  }

  private var siteLicensePricingTier: SiteLicensePricingTier? {
    guard fulfillmentPolicy.mode == .siteLicense else {
      return nil
    }

    return SiteLicensePricingStore().tier(for: fulfillmentPolicy.purchasedQuantity)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          previewCard("License") {
            row("Policy", fulfillmentPolicy.displayName)
            row("Type", fulfillmentPolicy.licenseTypeLabel)
            row("Product", item?.product?.name ?? "UpDock Pro")
            row("Quantity", "\(licenseQuantity)")
            if fulfillmentPolicy.mode == .siteLicense {
              row("Seat Allowance", "\(fulfillmentPolicy.purchasedQuantity)")
            }
            row("Serials", "Generated during fulfillment")
            row("Expiration", "None")
          }

          previewCard("Customer") {
            row("Name", transaction?.customerName ?? "—")
            row("Email", transaction?.customerEmail ?? "—")
            row("Customer ID", transaction?.customerID ?? transaction?.customer?.id ?? "—")
          }

          previewCard("Paddle") {
            row("Transaction ID", purchase.transactionID)
            row("Environment", purchase.paddleEnvironmentLabel)
            row("Status", transaction?.status ?? "—")
            row("Product ID", item?.product?.id ?? item?.price?.productID ?? "—")
            row("Price ID", item?.price?.id ?? "—")
          }

          if let siteLicensePricingTier {
            previewCard("Site License Pricing") {
              row("Range", siteLicensePricingTier.rangeLabel)
              row("Discount", percentText(siteLicensePricingTier.discountPercent))
              row("Discount Amount", moneyText(siteLicensePricingTier.discountAmount))
              row("Per Seat", moneyText(siteLicensePricingTier.unitPrice))
              row("Expected Total", moneyText(siteLicensePricingTier.unitPrice * Double(fulfillmentPolicy.purchasedQuantity)))
            }
          }

          previewCard("Fulfillment") {
            row("Local Action", localActionText)
            row("Web Action", "Archive transaction")
            row("Email", "Optional draft after license creation")
          }
        }
        .padding(24)
      }
      .navigationTitle("License Preview")
      .toolbar {
        ToolbarItem {
          Button("Close") {
            dismiss()
          }
        }
      }
    }
    .frame(width: 640, height: 540)
  }

  private func previewCard<Content: View>(
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
        .frame(width: 130, alignment: .leading)

      Text(value.isEmpty ? "—" : value)
        .textSelection(.enabled)
    }
  }

  private var localActionText: String {
    switch fulfillmentPolicy.mode {
    case .individualSeats:
      return "Create \(fulfillmentPolicy.generatedLicenseCount) commercial license\(fulfillmentPolicy.generatedLicenseCount == 1 ? "" : "s")"
    case .siteLicense:
      return "Create one commercial site license"
    }
  }

  private func moneyText(_ value: Double) -> String {
    String(format: "$%.2f", value)
  }

  private func percentText(_ value: Double) -> String {
    if value.rounded() == value {
      return "\(Int(value))%"
    }

    return "\(value)%"
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
