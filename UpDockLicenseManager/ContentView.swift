import SwiftUI
import UniformTypeIdentifiers

enum LicenseSidebarFilter: String, CaseIterable, Identifiable {
  case all = "All Licenses"
  case needsEmail = "Needs Email"
  case active = "Active"
  case activeBeta = "Active Beta"
  case activeTrial = "Active Trial"
  case activeCommercial = "Active Commercial"
  case expiringSoon = "Expiring Soon"
  case expired = "Expired"
  case revoked = "Revoked"

  var id: String { rawValue }

  var symbol: String {
    switch self {
    case .all: return "key"
    case .needsEmail: return "envelope.badge"
    case .active: return "checkmark.circle"
    case .activeBeta: return "testtube.2"
    case .activeTrial: return "hourglass"
    case .activeCommercial: return "seal"
    case .expiringSoon: return "clock"
    case .expired: return "exclamationmark.triangle"
    case .revoked: return "xmark.circle"
    }
  }
}

enum LicenseSortOption: String, CaseIterable, Identifiable {
  case newestFirst = "Newest First"
  case oldestFirst = "Oldest First"
  case name = "Name"
  case email = "Email"
  case expiration = "Expiration"
  case type = "License Type"
  case status = "Status"

  var id: String { rawValue }
}

enum RecoveryReportActionError: LocalizedError {
  case missingLicense

  var errorDescription: String? {
    switch self {
    case .missingLicense:
      return "The linked license could not be found."
    }
  }
}

struct ContentView: View {
  @AppStorage("showToolbarTextLabels") private var showToolbarTextLabels = false

  @State private var store = LicenseStore()
  @State private var auditLog = AuditLogStore()

  @State private var selectedFilter: LicenseSidebarFilter = .all
  @State private var selectedLicense: LicenseRecord?
  @State private var searchText = ""
  @State private var sortOption: LicenseSortOption = .newestFirst

  @State private var showingNewLicenseSheet = false
  @State private var exportError: String?
  @State private var showingExportError = false

  @State private var licensePendingDeletion: LicenseRecord?
  @State private var showingDeleteConfirmation = false
  @State private var lastDeletedLicense: LicenseRecord?

  @State private var inspectedLicense: ImportedLicenseInspection?
  @State private var showingInspectionError = false
  @State private var inspectionError: String?

  @State private var showingPaddleFulfillmentSheet = false
  @State private var showingPendingPurchases = false
  @State private var showingAuditLog = false
  @State private var showingRecoveryReport = false

  var body: some View {
    NavigationSplitView {
      LicenseSidebar(
        store: store,
        selectedFilter: $selectedFilter
      )
    } content: {
      LicenseListView(
        licenses: filteredLicenses,
        allLicenses: store.licenses,
        selectedLicense: $selectedLicense,
        searchText: searchText
      )
    } detail: {
      if let selectedLicense {
        LicenseDetailView(
          license: selectedLicense,
          auditEvents: auditLog.events(for: selectedLicense),
          relatedPaddleLicenseCount: relatedPaddleLicenseCount(for: selectedLicense),
          paddleSeatBadgeText: LicenseSeatBadgeContext.make(
            for: selectedLicense,
            in: store.licenses
          ).badgeText,
          onSave: { license in
            updateLicense(license)
          },
          onCopySerial: {
            LicenseService.copySerial(selectedLicense.serial)
          },
          onRevoke: {
            updateLicense(LicenseService.revokeLicense(selectedLicense))
          },
          onPrepareEmailDelivery: { license in
            try prepareEmailDelivery(for: license)
          },
          onMarkEmailSent: { license in
            markEmailSent(for: license)
          },
          onRefreshFulfillmentArchive: { license in
            try await refreshFulfillmentArchive(for: license)
          }
        )
        .id(selectedLicense.id)
      } else {
        LicenseDashboardView(store: store)
      }
    }
    .frame(minWidth: 1000, minHeight: 650)
    .toolbar {


      LicenseToolbarContent(
        selectedLicense: selectedLicense,
        showsTextLabels: showToolbarTextLabels,
        sortOption: $sortOption,
        onNew: {
          showingNewLicenseSheet = true
        },
        onFulfillPaddlePurchase: {
          showingPaddleFulfillmentSheet = true
        },
        onDuplicate: duplicateSelectedLicense,
        onDelete: confirmDeleteSelectedLicense,
        onExportJSON: exportJSON,
        onExportCSV: exportCSV,
        onUndoDelete: undoLastDelete,
        canUndoDelete: lastDeletedLicense != nil,
        onExportLicenseFile: exportLicenseFile,
        onInspectLicenseFile: inspectLicenseFile,
        onExportAndRevealLicenseFile: exportAndRevealLicenseFile,
        onExportAndEmailLicenseFile: exportAndEmailLicenseFile,
        onShowPendingPurchases: {
          showingPendingPurchases = true
        },
        onShowAuditLog: {
          showingAuditLog = true
        },
        onShowRecoveryReport: {
          showingRecoveryReport = true
        }
      )


    }
    .searchable(text: $searchText, placement: .toolbar, prompt: "Search licenses")
    .sheet(isPresented: $showingNewLicenseSheet) {
      NewLicenseSheet { license in
        store.add(license)
        recordAudit(
          .licenseCreated,
          license: license,
          message: "Created \(license.type.rawValue.lowercased()) license."
        )
        selectedFilter = .all
        selectedLicense = license
      }
    }

    .sheet(isPresented: $showingPaddleFulfillmentSheet) {
      PaddleFulfillmentSheet(
        existingLicenseForTransactionID: { transactionID in
          store.licenseForPaddleTransactionID(transactionID)
        },
        onCreate: { license in
          store.add(license)
          recordAudit(
            .paddleFulfilled,
            license: license,
            message: "Created commercial license from Paddle purchase."
          )
          selectedFilter = .all
          selectedLicense = license
        },
        onShowExisting: { license in
          selectedFilter = .all
          selectedLicense = license
        }
      )
    }
    .sheet(item: $inspectedLicense) { inspection in
      LicenseInspectionView(inspection: inspection)
    }
    .alert("Export Failed", isPresented: $showingExportError) {
      Button("OK") {}
    } message: {
      Text(exportError ?? "Unknown error")
    }
    .sheet(isPresented: $showingPendingPurchases) {
      PendingPurchasesView(
        existingLicensesForTransactionID: { transactionID in
          store.licensesForPaddleTransactionID(transactionID)
        },
        onFulfillPurchase: { createdLicenses, updatedExistingLicenses in
          for license in updatedExistingLicenses {
            updateLicense(license, auditChanges: false)
          }

          for license in createdLicenses {
            store.add(license)
            recordAudit(
              .paddleFulfilled,
              license: license,
              message: "Created commercial license from pending Paddle purchase."
            )
          }

          guard let selectedFulfilledLicense = createdLicenses.first ?? updatedExistingLicenses.first else {
            return
          }

          if createdLicenses.isEmpty {
            recordAudit(
              .fulfillmentChecked,
              license: selectedFulfilledLicense,
              message: "Confirmed Paddle purchase fulfillment archive."
            )
          }

          selectedFilter = .all
          selectedLicense = selectedFulfilledLicense
        },
        onPrepareEmailDrafts: { licenses in
          prepareEmailDraftsAfterFulfillment(for: licenses)
        }
      )
    }
    .sheet(isPresented: $showingAuditLog) {
      AuditLogView(
        events: auditLog.events,
        onExport: exportAuditLog
      )
    }
    .sheet(isPresented: $showingRecoveryReport) {
      RecoveryReportView(
        issues: recoveryIssues,
        onSelectLicense: { licenseID in
          selectLicense(id: licenseID)
        },
        onExport: {
          exportRecoveryReportCSV()
        },
        onRefreshFulfillmentArchive: { licenseID in
          try await refreshFulfillmentArchiveForRecoveryReport(licenseID: licenseID)
        }
      )
    }

    .alert("Delete License?", isPresented: $showingDeleteConfirmation) {
      Button("Cancel", role: .cancel) {
        licensePendingDeletion = nil
      }

      Button("Delete", role: .destructive) {
        deletePendingLicense()
      }
    } message: {
      if let licensePendingDeletion {
        Text("This will permanently remove \(licensePendingDeletion.serial) from License Manager. You can undo this immediately after deleting.")
      } else {
        Text("This license will be removed from License Manager.")
      }
    }
    .alert("Inspection Failed", isPresented: $showingInspectionError) {
      Button("OK") {}
    } message: {
      Text(inspectionError ?? "Unknown error")
    }
  }


  private func undoLastDelete() {
    guard let lastDeletedLicense else { return }

    store.add(lastDeletedLicense)
    recordAudit(
      .licenseRestored,
      license: lastDeletedLicense,
      message: "Restored deleted license."
    )
    selectedFilter = .all
    selectedLicense = lastDeletedLicense
    self.lastDeletedLicense = nil
  }

  private var filteredLicenses: [LicenseRecord] {
    let filtered = store.licenses.filter { license in
      let matchesFilter: Bool

      switch selectedFilter {
      case .all:
        matchesFilter = true
      case .needsEmail:
        matchesFilter = license.needsEmailDelivery
      case .active:
        matchesFilter = license.status == .active
      case .activeBeta:
        matchesFilter = license.status == .active && license.type == .beta
      case .activeTrial:
        matchesFilter = license.status == .active && license.type == .trial
      case .activeCommercial:
        matchesFilter = license.status == .active && license.type == .commercial
      case .expiringSoon:
        matchesFilter = license.status == .expiringSoon
      case .expired:
        matchesFilter = license.status == .expired
      case .revoked:
        matchesFilter = license.status == .revoked
      }

      let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !trimmedSearch.isEmpty else {
        return matchesFilter
      }

      let searchable = [
        license.serial,
        license.type.rawValue,
        license.product,
        license.name,
        license.email,
        license.notes,
        license.status.rawValue
      ]
        .joined(separator: " ")

      return matchesFilter && searchable.localizedCaseInsensitiveContains(trimmedSearch)
    }

    return sorted(filtered)
  }

  private var recoveryIssues: [RecoveryIssue] {
    var issues: [RecoveryIssue] = []
    let duplicateSerials = duplicateValues(store.licenses.map(\.serial))

    for license in store.licenses {
      let trimmedSerial = license.serial.trimmingCharacters(in: .whitespacesAndNewlines)
      let trimmedTransactionID = license.paddleTransactionID.trimmingCharacters(
        in: .whitespacesAndNewlines
      )

      if duplicateSerials.contains(trimmedSerial) {
        issues.append(
          RecoveryIssue(
            severity: .failure,
            title: "Duplicate Serial",
            detail: "More than one local license has this serial number.",
            license: license
          )
        )
      }

      if license.type == .commercial && trimmedTransactionID.isEmpty {
        issues.append(
          RecoveryIssue(
            severity: .warning,
            title: "Commercial License Missing Paddle ID",
            detail: "Commercial licenses should normally link back to a Paddle transaction.",
            license: license
          )
        )
      }

      if !trimmedTransactionID.isEmpty && license.fulfillmentArchiveStatus != .archived {
        issues.append(
          RecoveryIssue(
            severity: license.fulfillmentArchiveStatus == .notFound ? .failure : .warning,
            title: "Fulfillment Archive Not Confirmed",
            detail: "Current web archive status is \(license.fulfillmentArchiveStatus.rawValue).",
            license: license
          )
        )
      }

      if license.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        issues.append(
          RecoveryIssue(
            severity: .failure,
            title: "Missing Customer Email",
            detail: "No customer email is stored for this license.",
            license: license
          )
        )
      } else if license.emailDeliveryStatus != .sent {
        issues.append(
          RecoveryIssue(
            severity: license.emailDeliveryStatus == .failed ? .failure : .warning,
            title: "Customer Email Not Sent",
            detail: "Current email status is \(license.emailDeliveryStatus.rawValue).",
            license: license
          )
        )
      }

      if !license.paddleEmail.isEmpty
        && !license.email.isEmpty
        && license.paddleEmail.localizedCaseInsensitiveCompare(license.email) != .orderedSame {
        issues.append(
          RecoveryIssue(
            severity: .warning,
            title: "Paddle Email Mismatch",
            detail: "Paddle email and license email do not match.",
            license: license
          )
        )
      }

      if isSiteLicenseLike(license) && license.seatAllowance == nil {
        issues.append(
          RecoveryIssue(
            severity: .warning,
            title: "Site License Missing Seat Allowance",
            detail: "Set the purchased seat allowance in Seat Usage.",
            license: license
          )
        )
      }

      if let seatAllowance = license.seatAllowance,
         license.seatsAssigned > seatAllowance {
        issues.append(
          RecoveryIssue(
            severity: .failure,
            title: "Seat Assignment Over Limit",
            detail: "Assigned seats exceed the site-license allowance.",
            license: license
          )
        )
      }

      if license.seatAllowance != nil && license.activationRegistryStatus == .failed {
        issues.append(
          RecoveryIssue(
            severity: .failure,
            title: "Activation Registration Failed",
            detail: license.activationRegistryError.isEmpty
              ? "The site license was not registered with the activation registry."
              : license.activationRegistryError,
            license: license
          )
        )
      }

      if license.seatAllowance != nil && license.activationRegistryStatus == .unknown {
        issues.append(
          RecoveryIssue(
            severity: .warning,
            title: "Activation Registration Not Confirmed",
            detail: "The site license has no confirmed activation registry registration.",
            license: license
          )
        )
      }

      if auditLog.events(for: license).isEmpty {
        issues.append(
          RecoveryIssue(
            severity: .warning,
            title: "Missing Audit Trail",
            detail: "No audit events are linked to this license.",
            license: license
          )
        )
      }
    }

    return issues.sorted {
      if $0.severity != $1.severity {
        return $0.severity == .failure
      }

      return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
    }
  }

  private func isSiteLicenseLike(_ license: LicenseRecord) -> Bool {
    let searchable = [
      license.product,
      license.notes
    ]
      .joined(separator: " ")
      .lowercased()

    return searchable.contains("site license") || searchable.contains("site-license")
  }

  private func sorted(_ licenses: [LicenseRecord]) -> [LicenseRecord] {
    switch sortOption {
    case .newestFirst:
      return licenses.sorted { $0.issuedAt > $1.issuedAt }
    case .oldestFirst:
      return licenses.sorted { $0.issuedAt < $1.issuedAt }
    case .name:
      return licenses.sorted {
        $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
      }
    case .email:
      return licenses.sorted {
        $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending
      }
    case .expiration:
      return licenses.sorted {
        ($0.expiresAt ?? .distantFuture) < ($1.expiresAt ?? .distantFuture)
      }
    case .type:
      return licenses.sorted {
        $0.type.rawValue.localizedCaseInsensitiveCompare($1.type.rawValue) == .orderedAscending
      }
    case .status:
      return licenses.sorted {
        $0.status.rawValue.localizedCaseInsensitiveCompare($1.status.rawValue) == .orderedAscending
      }
    }
  }

  private func duplicateValues(_ values: [String]) -> Set<String> {
    var seen: Set<String> = []
    var duplicates: Set<String> = []

    for value in values {
      let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

      guard !trimmed.isEmpty else {
        continue
      }

      if seen.contains(trimmed) {
        duplicates.insert(trimmed)
      } else {
        seen.insert(trimmed)
      }
    }

    return duplicates
  }

  private func relatedPaddleLicenseCount(for license: LicenseRecord) -> Int {
    let transactionID = license.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !transactionID.isEmpty else {
      return 1
    }

    return max(store.licensesForPaddleTransactionID(transactionID).count, 1)
  }

  private func selectLicense(id: UUID) {
    guard let license = store.licenses.first(where: { $0.id == id }) else {
      return
    }

    selectedFilter = .all
    selectedLicense = license
  }

  private func updateLicense(_ updated: LicenseRecord, auditChanges: Bool = true) {
    guard let index = store.licenses.firstIndex(where: { $0.id == updated.id }) else { return }
    let original = store.licenses[index]
    store.licenses[index] = updated
    selectedLicense = updated

    if auditChanges && original != updated {
      recordAudit(
        updated.isRevoked && !original.isRevoked ? .licenseRevoked : .licenseUpdated,
        license: updated,
        message: updated.isRevoked && !original.isRevoked
          ? "Revoked license."
          : "Updated license details."
      )
    }
  }

  private func refreshFulfillmentArchive(for license: LicenseRecord) async throws -> LicenseRecord {
    let updatedLicense = try await FulfillmentCoordinator.shared.verifyFulfillmentArchive(
      for: license,
      settings: NetworkSettings()
    )

    updateLicense(updatedLicense, auditChanges: false)
    recordAudit(
      .fulfillmentChecked,
      license: updatedLicense,
      message: "Checked website fulfillment status: \(updatedLicense.fulfillmentArchiveStatus.rawValue)."
    )

    return updatedLicense
  }

  private func refreshFulfillmentArchiveForRecoveryReport(licenseID: UUID) async throws -> String {
    guard let license = store.licenses.first(where: { $0.id == licenseID }) else {
      throw RecoveryReportActionError.missingLicense
    }

    let updatedLicense = try await refreshFulfillmentArchive(for: license)
    return "Website archive status: \(updatedLicense.fulfillmentArchiveStatus.rawValue)."
  }

  private func prepareEmailDelivery(for license: LicenseRecord) throws -> LicenseRecord {
    do {
      let updatedLicense = try LicenseDistributionService.exportAndEmailLicenseFile(
        record: license,
        store: store
      )

      updateLicense(updatedLicense, auditChanges: false)
      recordAudit(
        .emailDraftPrepared,
        license: updatedLicense,
        message: "Prepared Mail draft for \(updatedLicense.email)."
      )

      return updatedLicense
    } catch {
      var failedLicense = license
      failedLicense.emailDeliveryStatus = .failed
      failedLicense.emailDeliveryAttemptedAt = Date()
      failedLicense.emailDeliveryError = error.localizedDescription
      updateLicense(failedLicense, auditChanges: false)
      recordAudit(
        .emailDraftFailed,
        license: failedLicense,
        message: "Email draft failed: \(error.localizedDescription)"
      )

      throw error
    }
  }

  private func prepareEmailDraftsAfterFulfillment(
    for licenses: [LicenseRecord]
  ) -> EmailDraftPreparationResult {
    var preparedCount = 0
    var failedCount = 0
    var skippedCount = 0

    for license in licenses {
      guard !license.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        skippedCount += 1
        continue
      }

      do {
        _ = try prepareEmailDelivery(for: license)
        preparedCount += 1
      } catch {
        failedCount += 1
      }
    }

    return EmailDraftPreparationResult(
      preparedCount: preparedCount,
      failedCount: failedCount,
      skippedCount: skippedCount
    )
  }

  private func markEmailSent(for license: LicenseRecord) -> LicenseRecord {
    var updatedLicense = license
    updatedLicense.emailDeliveryStatus = .sent
    updatedLicense.emailDeliveryAttemptedAt = Date()
    updatedLicense.emailDeliveryError = ""

    updateLicense(updatedLicense, auditChanges: false)
    recordAudit(
      .emailMarkedSent,
      license: updatedLicense,
      message: "Marked customer email as sent to \(updatedLicense.email)."
    )

    return updatedLicense
  }

  private func duplicateSelectedLicense() {
    guard let selectedLicense else { return }
    let duplicate = LicenseService.duplicateLicense(selectedLicense)
    store.add(duplicate)
    recordAudit(
      .licenseDuplicated,
      license: duplicate,
      message: "Duplicated license from \(selectedLicense.serial)."
    )
    selectedFilter = .all
    self.selectedLicense = duplicate
  }

  private func confirmDeleteSelectedLicense() {
    guard let selectedLicense else { return }
    licensePendingDeletion = selectedLicense
    showingDeleteConfirmation = true
  }

  private func deletePendingLicense() {
    guard let license = licensePendingDeletion else { return }

    lastDeletedLicense = license
    store.delete([license])
    recordAudit(
      .licenseDeleted,
      license: license,
      message: "Deleted license."
    )

    if selectedLicense?.id == license.id {
      selectedLicense = nil
    }

    licensePendingDeletion = nil
  }

  private func exportJSON() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = "updock-pro-licenses.json"

    if panel.runModal() == .OK, let url = panel.url {
      do {
        try store.exportJSON(to: url)
        recordAudit(
          .licenseExported,
          message: "Exported license database JSON to \(url.lastPathComponent)."
        )
      } catch {
        exportError = error.localizedDescription
        showingExportError = true
      }
    }
  }

  private func exportCSV() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [
      UTType(filenameExtension: "csv") ?? .plainText
    ]
    panel.nameFieldStringValue = "updock-pro-licenses.csv"

    if panel.runModal() == .OK, let url = panel.url {
      do {
        try store.exportCSV(to: url)
        recordAudit(
          .licenseExported,
          message: "Exported license CSV to \(url.lastPathComponent)."
        )
      } catch {
        exportError = error.localizedDescription
        showingExportError = true
      }
    }
  }

  private func inspectLicenseFile() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [
      UTType(filenameExtension: "updocklicense") ?? .json
    ]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false

    if panel.runModal() == .OK, let url = panel.url {
      do {
        inspectedLicense = try LicenseInspectionService.inspectLicenseFile(at: url)
      } catch {
        inspectionError = error.localizedDescription
        showingInspectionError = true
      }
    }
  }

  private func exportAndRevealLicenseFile() {
    guard let selectedLicense else { return }

    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false
    panel.prompt = "Export"

    if panel.runModal() == .OK, let folderURL = panel.url {
      do {
        try LicenseDistributionService.exportAndRevealLicenseFile(
          record: selectedLicense,
          store: store,
          folderURL: folderURL
        )
        recordAudit(
          .licenseExported,
          license: selectedLicense,
          message: "Exported and revealed license file."
        )
      } catch {
        exportError = error.localizedDescription
        showingExportError = true
      }
    }
  }

  private func exportAndEmailLicenseFile() {
    guard let selectedLicense else { return }

    do {
      _ = try prepareEmailDelivery(for: selectedLicense)
    } catch {
      exportError = error.localizedDescription
      showingExportError = true
    }
  }

  private func exportLicenseFile() {
    guard let selectedLicense else { return }

    let panel = NSSavePanel()
    panel.allowedContentTypes = [
      UTType(filenameExtension: "updocklicense") ?? .json
    ]

    panel.nameFieldStringValue = LicenseFileNameService.suggestedLicenseFileName(for: selectedLicense)

    if panel.runModal() == .OK, let url = panel.url {
      do {
        try LicenseDistributionService.exportLicenseFile(
          record: selectedLicense,
          store: store,
          to: url
        )
        recordAudit(
          .licenseExported,
          license: selectedLicense,
          message: "Exported license file to \(url.lastPathComponent)."
        )
      } catch {
        exportError = error.localizedDescription
        showingExportError = true
      }
    }
  }

  private func exportAuditLog() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = "updock-license-manager-audit-log.json"

    if panel.runModal() == .OK, let url = panel.url {
      do {
        try auditLog.exportJSON(to: url)
      } catch {
        exportError = error.localizedDescription
        showingExportError = true
      }
    }
  }

  private func exportRecoveryReportCSV() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [
      UTType(filenameExtension: "csv") ?? .plainText
    ]
    panel.nameFieldStringValue = "updock-license-manager-recovery-report.csv"

    if panel.runModal() == .OK, let url = panel.url {
      do {
        try makeRecoveryReportCSV().write(to: url, atomically: true, encoding: .utf8)
      } catch {
        exportError = error.localizedDescription
        showingExportError = true
      }
    }
  }

  private func makeRecoveryReportCSV() -> String {
    let header = [
      "Group Type",
      "Group",
      "Group Failures",
      "Group Warnings",
      "Issue Severity",
      "Issue Title",
      "Issue Detail",
      "Transaction ID",
      "Customer Email",
      "License Serial",
      "License ID"
    ]

    let rows = RecoveryIssueGroup.makeGroups(from: recoveryIssues).flatMap { group in
      group.issues.map { issue in
        [
          recoveryGroupType(for: group),
          group.title,
          "\(group.failureCount)",
          "\(group.warningCount)",
          issue.severity.rawValue,
          issue.title,
          issue.detail,
          issue.paddleTransactionID,
          issue.customerEmail,
          issue.licenseSerial,
          issue.licenseID?.uuidString ?? ""
        ]
      }
    }

    return ([header] + rows)
      .map { row in
        row.map(csvEscape).joined(separator: ",")
      }
      .joined(separator: "\n")
  }

  private func recoveryGroupType(for group: RecoveryIssueGroup) -> String {
    if !group.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "Transaction"
    }

    if !group.licenseSerial.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "License"
    }

    if !group.customerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return "Customer"
    }

    return "Issue"
  }

  private func csvEscape(_ value: String) -> String {
    let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  private func recordAudit(
    _ kind: AuditEventKind,
    license: LicenseRecord? = nil,
    message: String,
    paddleTransactionID: String = ""
  ) {
    auditLog.record(
      AuditEvent(
        kind: kind,
        message: message,
        license: license,
        paddleTransactionID: paddleTransactionID
      )
    )
  }
}
