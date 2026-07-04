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

struct ContentView: View {
  @State private var store = LicenseStore()

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

  var body: some View {
    NavigationSplitView {
      LicenseSidebar(
        store: store,
        selectedFilter: $selectedFilter
      )
    } content: {
      LicenseListView(
        licenses: filteredLicenses,
        selectedLicense: $selectedLicense,
        searchText: searchText
      )
    } detail: {
      if let selectedLicense {
        LicenseDetailView(
          license: selectedLicense,
          onSave: updateLicense,
          onCopySerial: {
            LicenseService.copySerial(selectedLicense.serial)
          },
          onRevoke: {
            updateLicense(LicenseService.revokeLicense(selectedLicense))
          },
          onPrepareEmailDelivery: { license in
            try prepareEmailDelivery(for: license)
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
        }
      )


    }
    .searchable(text: $searchText, placement: .toolbar, prompt: "Search licenses")
    .sheet(isPresented: $showingNewLicenseSheet) {
      NewLicenseSheet { license in
        store.add(license)
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
        existingLicenseForTransactionID: { transactionID in
          store.licenseForPaddleTransactionID(transactionID)
        },
        onFulfillPurchase: { license in
          store.add(license)
          selectedFilter = .all
          selectedLicense = license
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

  private func updateLicense(_ updated: LicenseRecord) {
    guard let index = store.licenses.firstIndex(where: { $0.id == updated.id }) else { return }
    store.licenses[index] = updated
    selectedLicense = updated
  }

  private func refreshFulfillmentArchive(for license: LicenseRecord) async throws -> LicenseRecord {
    let updatedLicense = try await FulfillmentCoordinator.shared.verifyFulfillmentArchive(
      for: license,
      settings: NetworkSettings()
    )

    updateLicense(updatedLicense)

    return updatedLicense
  }

  private func prepareEmailDelivery(for license: LicenseRecord) throws -> LicenseRecord {
    do {
      let updatedLicense = try LicenseDistributionService.exportAndEmailLicenseFile(
        record: license,
        store: store
      )

      updateLicense(updatedLicense)

      return updatedLicense
    } catch {
      var failedLicense = license
      failedLicense.emailDeliveryStatus = .failed
      failedLicense.emailDeliveryAttemptedAt = Date()
      failedLicense.emailDeliveryError = error.localizedDescription
      updateLicense(failedLicense)

      throw error
    }
  }

  private func duplicateSelectedLicense() {
    guard let selectedLicense else { return }
    let duplicate = LicenseService.duplicateLicense(selectedLicense)
    store.add(duplicate)
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
      } catch {
        exportError = error.localizedDescription
        showingExportError = true
      }
    }
  }

 }
