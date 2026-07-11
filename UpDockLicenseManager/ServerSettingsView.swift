//
//  ServerSettingsView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let localPrivateConfigBookmarkKey = "localPrivateConfigBookmark"

private struct ProductionReadinessItem: Identifiable {
  var title: String
  var status: ProductionReadinessStatus
  var detail: String

  var id: String {
    title
  }
}

private enum ProductionReadinessStatus {
  case ready
  case warning
  case notChecked
}

struct ServerSettingsView: View {
  @State private var settings = NetworkSettings()
  @State private var paddleSettings = PaddleSettings()
  @State private var emailSettings = EmailSettings()
  @State private var managerToken = KeychainSettingsStore.shared.managerToken
  @State private var showingToken = false
  @State private var healthResponse: HealthResponse?
  @State private var healthError: String?
  @State private var lastCheckedAt: Date?
  @State private var isCheckingConnection = false
  @State private var activationTestSerial = "TEST-SITE-001"
  @State private var activationTestSteps: [ActivationTestStep] = []
  @State private var isRunningActivationTest = false
  @State private var operationsStatus: OperationsStatusResponse?
  @State private var operationsStatusError: String?
  @State private var operationsStatusCheckedAt: Date?
  @State private var isFetchingOperationsStatus = false
  @State private var isSendingServerEmailTest = false
  @State private var serverEmailTestMessage = ""
  @State private var showingManagerTokenSyncAlert = false
  @State private var managerTokenConfigUpdateMessage = ""

  var body: some View {
    Form {
      Section("Server") {
        TextField(
          "Base URL",
          text: $settings.serverBaseURL
        )
        .textFieldStyle(.roundedBorder)

        LabeledContent("Health") {
          Text(settings.healthURL)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }

        LabeledContent("Pending") {
          Text(settings.pendingURL)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }

        LabeledContent("Fulfilled") {
          Text(settings.fulfilledURL)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }

        LabeledContent("Webhook") {
          Text(settings.webhookURL)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }

        LabeledContent("Operations Status") {
          HStack {
            Text(operationsStatusURL)
              .font(.caption.monospaced())
              .foregroundStyle(.secondary)
              .textSelection(.enabled)

            Button("Copy", systemImage: "doc.on.doc") {
              copyToPasteboard(operationsStatusURL)
            }
            .labelStyle(.iconOnly)
          }
        }
      }

      Section("Manager Token") {
        if showingToken {
          TextField(
            "Manager Token",
            text: $managerToken
          )
        } else {
          SecureField(
            "Manager Token",
            text: $managerToken
          )
        }

        HStack {
          Button(showingToken ? "Hide" : "Show") {
            showingToken.toggle()
          }

          Button("Generate") {
            managerToken = TokenGenerator.makeManagerToken()
            saveManagerToken()
          }

          Button("Copy") {
            copyToPasteboard(managerToken)
          }

          Button("Save") {
            saveManagerToken()
          }
          .buttonStyle(.borderedProminent)

          Button("Update Local Config…") {
            updateLocalPrivateConfigManagerToken()
          }
        }

        Text("Used by License Manager when communicating with pending.php and fulfilled.php.")
          .foregroundStyle(.secondary)

        if !managerTokenConfigUpdateMessage.isEmpty {
          Text(managerTokenConfigUpdateMessage)
            .foregroundStyle(.secondary)
        }
      }

      Section("Production Readiness") {
        HStack {
          Label(productionReadinessTitle, systemImage: productionReadinessSymbol)
            .foregroundStyle(productionReadinessStyle)

          Spacer()

          Text("\(productionReadyCount) of \(productionReadinessItems.count) ready")
            .foregroundStyle(.secondary)
        }

        ForEach(productionReadinessItems) { item in
          readinessRow(item)
        }

        Text("Use Test Connection and Refresh Operations to update server-side checks.")
          .foregroundStyle(.secondary)
      }

      Section("Connection") {
        HStack {
          Button {
            Task {
              await checkConnection()
            }
          } label: {
            if isCheckingConnection {
              ProgressView()
            } else {
              Label("Test Connection", systemImage: "network")
            }
          }
          .disabled(isCheckingConnection)

          if let lastCheckedAt {
            Text(lastCheckedAt.formatted(date: .abbreviated, time: .shortened))
              .foregroundStyle(.secondary)
          }
        }

        if let healthResponse {
          Label(connectionStatusTitle, systemImage: connectionStatusSymbol)
            .foregroundStyle(connectionStatusStyle)

          LabeledContent("PHP") {
            Text(healthResponse.php)
          }

          LabeledContent("Server Time") {
            Text(healthResponse.time)
          }

          LabeledContent("Transactions Folder") {
            writableLabel(healthResponse.transactionsWritable)
          }

          LabeledContent("Fulfilled Folder") {
            writableLabel(healthResponse.fulfilledWritable)
          }

          if let licensesWritable = healthResponse.licensesWritable {
            LabeledContent("Licenses Folder") {
              writableLabel(licensesWritable)
            }
          }

          if let activationsWritable = healthResponse.activationsWritable {
            LabeledContent("Activations Folder") {
              writableLabel(activationsWritable)
            }
          }

          if let deliveredLicensesWritable = healthResponse.deliveredLicensesWritable {
            LabeledContent("Delivered Licenses Folder") {
              writableLabel(deliveredLicensesWritable)
            }
          }

          if let webhookLogWritable = healthResponse.webhookLogWritable {
            LabeledContent("Webhook Log") {
              writableLabel(webhookLogWritable)
            }
          }

          if let autoFulfillment = healthResponse.autoFulfillment {
            LabeledContent("Auto-Fulfillment") {
              writableLabel(autoFulfillment.enabled ?? false)
            }

            if let signingKeyConfigured = autoFulfillment.signingKeyConfigured {
              LabeledContent("Server Signing Key") {
                writableLabel(signingKeyConfigured)
              }
            }

            if let sodiumAvailable = autoFulfillment.sodiumAvailable {
              LabeledContent("Sodium") {
                writableLabel(sodiumAvailable)
              }
            }

            if let mailAvailable = autoFulfillment.mailAvailable {
              LabeledContent("Server Mail") {
                writableLabel(mailAvailable)
              }
            }
          }
        }

        if let healthError {
          Label(healthError, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
        }
      }

      Section("Server Operations") {
        HStack {
          Button {
            Task {
              await fetchOperationsStatus()
            }
          } label: {
            if isFetchingOperationsStatus {
              ProgressView()
            } else {
              Label("Refresh Operations", systemImage: "arrow.clockwise")
            }
          }
          .disabled(isFetchingOperationsStatus)

          if let operationsStatusCheckedAt {
            Text(operationsStatusCheckedAt.formatted(date: .abbreviated, time: .shortened))
              .foregroundStyle(.secondary)
          }
        }

        if let operationsStatus {
          Label("Operations status loaded", systemImage: "checkmark.circle")
            .foregroundStyle(.green)

          LabeledContent("Pending") {
            Text("\(operationsStatus.counts.pendingTransactions)")
          }

          LabeledContent("Fulfilled") {
            Text("\(operationsStatus.counts.fulfilledTransactions)")
          }

          LabeledContent("Registered Licenses") {
            Text("\(operationsStatus.counts.registeredLicenses)")
          }

          LabeledContent("Delivered Licenses") {
            Text("\(operationsStatus.counts.deliveredLicenses ?? 0)")
          }

          LabeledContent("Active Activations") {
            Text("\(operationsStatus.counts.activeActivations)")
          }

          LabeledContent("Generated") {
            Text(operationsStatus.generatedAt)
              .textSelection(.enabled)
          }

          storageRow("Transactions", operationsStatus.storage.transactionsWritable)
          storageRow("Fulfilled", operationsStatus.storage.fulfilledWritable)
          storageRow("Licenses", operationsStatus.storage.licensesWritable)
          storageRow("Delivered Licenses", operationsStatus.storage.deliveredLicensesWritable ?? true)
          storageRow("Activations", operationsStatus.storage.activationsWritable)
          storageRow("Webhook Log", operationsStatus.storage.webhookLogWritable)

          if let deliveredLicenses = operationsStatus.latest.deliveredLicenses,
             !deliveredLicenses.isEmpty {
            Divider()

            Text("Latest Delivered Licenses")
              .font(.headline)

            ForEach(deliveredLicenses.prefix(5)) { license in
              VStack(alignment: .leading, spacing: 4) {
                Text(license.id)
                  .font(.system(.caption, design: .monospaced))
                  .textSelection(.enabled)

                HStack {
                  Text(license.updatedAt)
                  Text(license.file)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
              }
            }
          }

          if !operationsStatus.latest.webhookEvents.isEmpty {
            Divider()

            HStack {
              Text("Recent Webhook Events")
                .font(.headline)

              Spacer()

              Button("Copy Results", systemImage: "doc.on.doc") {
                copyWebhookEventResults()
              }
            }

            ForEach(operationsStatus.latest.webhookEvents.prefix(5)) { event in
              VStack(alignment: .leading, spacing: 4) {
                Label(event.message, systemImage: webhookSymbol(for: event.status))
                  .foregroundStyle(webhookStyle(for: event.status))

                HStack {
                  Text(event.status)
                  if let time = event.time {
                    Text(time)
                  }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

                if let context = event.context, !context.isEmpty {
                  VStack(alignment: .leading, spacing: 3) {
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
            }
          }
        }

        if let operationsStatusError {
          Label(operationsStatusError, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
        }
      }

      Section("Server Email Test") {
        LabeledContent("Recipient") {
          Text(serverEmailTestRecipient)
            .textSelection(.enabled)
        }

        Button {
          Task {
            await sendServerEmailTest()
          }
        } label: {
          if isSendingServerEmailTest {
            ProgressView()
          } else {
            Label("Send Test License Email", systemImage: "paperplane")
          }
        }
        .disabled(isSendingServerEmailTest || serverEmailTestRecipient.isEmpty)

        Text("Sends a fake license attachment through the private server email path. It does not create or fulfill a real license.")
          .foregroundStyle(.secondary)

        if !serverEmailTestMessage.isEmpty {
          Text(serverEmailTestMessage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }
      }

      Section("Activation Test") {
        TextField("Serial", text: $activationTestSerial)
          .textFieldStyle(.roundedBorder)

        LabeledContent("Seat Allowance") {
          Text("2")
        }

        activationURLRow(
          "Register",
          settings.activationRegisterURL(
            serial: activationTestSerial,
            seatAllowance: 2
          )
        )

        activationURLRow(
          "Activate Mac 1",
          settings.activationURL(
            serial: activationTestSerial,
            machineID: "mac-1",
            machineName: "Mac 1"
          )
        )

        activationURLRow(
          "Activate Mac 2",
          settings.activationURL(
            serial: activationTestSerial,
            machineID: "mac-2",
            machineName: "Mac 2"
          )
        )

        activationURLRow(
          "Activate Mac 3",
          settings.activationURL(
            serial: activationTestSerial,
            machineID: "mac-3",
            machineName: "Mac 3"
          )
        )

        activationURLRow(
          "Deactivate Mac 1",
          settings.deactivationURL(
            serial: activationTestSerial,
            machineID: "mac-1"
          )
        )

        activationURLRow(
          "Status",
          settings.activationStatusURL(serial: activationTestSerial)
        )

        HStack {
          Button {
            Task {
              await runActivationLimitTest()
            }
          } label: {
            if isRunningActivationTest {
              ProgressView()
            } else {
              Label("Run 2-Seat Test", systemImage: "checklist")
            }
          }
          .disabled(isRunningActivationTest)

          Text("The third activation should be rejected.")
            .foregroundStyle(.secondary)
        }

        if !activationTestSteps.isEmpty {
          ForEach(activationTestSteps) { step in
            HStack {
              Label(
                step.title,
                systemImage: step.passed ? "checkmark.circle" : "xmark.circle"
              )
              .foregroundStyle(step.passed ? AnyShapeStyle(.green) : AnyShapeStyle(.red))

              Spacer()

              Text("HTTP \(step.statusCode.map(String.init) ?? "—") / expected \(step.expectedStatusCode)")
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
    .formStyle(.grouped)
    .padding()
    .alert("Manager Token Saved", isPresented: $showingManagerTokenSyncAlert) {
      Button("Update Local Config") {
        updateLocalPrivateConfigManagerToken()
      }

      Button("Copy Token") {
        copyToPasteboard(managerToken)
      }

      Button("OK") {}
    } message: {
      Text("Update UPDOCK_MANAGER_TOKEN in the private paddle-config.php file, then sync that private file separately to the server. The app will ask you to choose the file once if needed.")
    }
  }

  private var connectionStatusTitle: String {
    guard let healthResponse else {
      return "Not Checked"
    }

    guard storageIsReady(healthResponse) else {
      return "Connected, but storage needs attention"
    }

    return healthResponse.status.localizedCaseInsensitiveContains("ok")
      ? "Connected"
      : healthResponse.status
  }

  private var connectionStatusSymbol: String {
    guard let healthResponse else {
      return "questionmark.circle"
    }

    return storageIsReady(healthResponse)
      ? "checkmark.circle"
      : "exclamationmark.triangle"
  }

  private var connectionStatusStyle: AnyShapeStyle {
    guard let healthResponse else {
      return AnyShapeStyle(.secondary)
    }

    return storageIsReady(healthResponse)
      ? AnyShapeStyle(.green)
      : AnyShapeStyle(.orange)
  }

  private var operationsStatusURL: String {
    settings.authenticatedOperationsStatusURL(token: managerToken)
  }

  private var serverEmailTestRecipient: String {
    emailSettings.signatureEmail.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var productionReadinessItems: [ProductionReadinessItem] {
    [
      ProductionReadinessItem(
        title: "Signing Key",
        status: signingKeyIsPresent ? .ready : .warning,
        detail: signingKeyIsPresent ? "Signing identity is present." : "Create or import a signing identity."
      ),
      ProductionReadinessItem(
        title: "Manager Token",
        status: managerToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .warning : .ready,
        detail: managerToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
          ? "Generate and save a manager token."
          : "Manager token is present."
      ),
      ProductionReadinessItem(
        title: "Paddle API Key",
        status: keychainValueIsPresent(KeychainSettingsStore.shared.paddleAPIKey) ? .ready : .warning,
        detail: keychainValueIsPresent(KeychainSettingsStore.shared.paddleAPIKey)
          ? "Paddle API key is saved locally."
          : "Save a Paddle API key in Paddle Settings."
      ),
      ProductionReadinessItem(
        title: "Paddle Webhook Secret",
        status: keychainValueIsPresent(KeychainSettingsStore.shared.paddleNotificationSecret) ? .ready : .warning,
        detail: keychainValueIsPresent(KeychainSettingsStore.shared.paddleNotificationSecret)
          ? "Webhook secret is saved locally."
          : "Save the Paddle notification secret in Paddle Settings."
      ),
      privateConfigReadinessItem,
      paddleEnvironmentReadinessItem,
      serverHealthReadinessItem,
      storageReadinessItem,
      operationsReadinessItem,
      pendingQueueReadinessItem,
      webhookReadinessItem,
      emailDraftReadinessItem
    ]
  }

  private var productionReadyCount: Int {
    productionReadinessItems.filter { $0.status == .ready }.count
  }

  private var productionReadinessTitle: String {
    let warningCount = productionReadinessItems.filter { $0.status == .warning }.count
    let notCheckedCount = productionReadinessItems.filter { $0.status == .notChecked }.count

    if warningCount == 0 && notCheckedCount == 0 {
      return "Ready for production review"
    }

    if warningCount > 0 {
      return "\(warningCount) item\(warningCount == 1 ? "" : "s") need attention"
    }

    return "\(notCheckedCount) item\(notCheckedCount == 1 ? "" : "s") not checked"
  }

  private var productionReadinessSymbol: String {
    productionReadinessItems.contains { $0.status == .warning }
      ? "exclamationmark.triangle"
      : productionReadinessItems.contains { $0.status == .notChecked }
        ? "questionmark.circle"
        : "checkmark.circle"
  }

  private var productionReadinessStyle: AnyShapeStyle {
    if productionReadinessItems.contains(where: { $0.status == .warning }) {
      return AnyShapeStyle(.orange)
    }

    if productionReadinessItems.contains(where: { $0.status == .notChecked }) {
      return AnyShapeStyle(.secondary)
    }

    return AnyShapeStyle(.green)
  }

  private var signingKeyIsPresent: Bool {
    (try? SigningIdentityStore.loadPrivateKey()) != nil
  }

  private func keychainValueIsPresent(_ value: String) -> Bool {
    !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private var privateConfigReadinessItem: ProductionReadinessItem {
    guard let healthResponse else {
      return ProductionReadinessItem(
        title: "Private Web Config",
        status: .notChecked,
        detail: "Run Test Connection."
      )
    }

    let isLoaded = healthResponse.privateConfigLoaded ?? false
    return ProductionReadinessItem(
      title: "Private Web Config",
      status: isLoaded ? .ready : .warning,
      detail: isLoaded ? "Private config is loaded on the server." : "Private config is not loaded on the server."
    )
  }

  private var paddleEnvironmentReadinessItem: ProductionReadinessItem {
    guard let healthResponse else {
      return ProductionReadinessItem(
        title: "Paddle Environment",
        status: .notChecked,
        detail: "Run Test Connection."
      )
    }

    let serverMode = healthResponse.paddleApiMode?.lowercased() ?? "unknown"
    let appMode = paddleSettings.environment == .sandbox ? "sandbox" : "production"

    guard serverMode != "unknown" else {
      return ProductionReadinessItem(
        title: "Paddle Environment",
        status: .warning,
        detail: "Server Paddle API mode is unknown. Sync the latest public web files and private config."
      )
    }

    return ProductionReadinessItem(
      title: "Paddle Environment",
      status: serverMode == appMode ? .ready : .warning,
      detail: serverMode == appMode
        ? "App and server are both using \(paddleSettings.environment.rawValue)."
        : "App is \(paddleSettings.environment.rawValue), but server is \(serverMode)."
    )
  }

  private var serverHealthReadinessItem: ProductionReadinessItem {
    guard let healthResponse else {
      return ProductionReadinessItem(
        title: "Server Health",
        status: .notChecked,
        detail: "Run Test Connection."
      )
    }

    let isHealthy = healthResponse.status.localizedCaseInsensitiveContains("ok")
    return ProductionReadinessItem(
      title: "Server Health",
      status: isHealthy ? .ready : .warning,
      detail: isHealthy ? "Server health endpoint is OK." : "Server returned \(healthResponse.status)."
    )
  }

  private var storageReadinessItem: ProductionReadinessItem {
    guard let healthResponse else {
      return ProductionReadinessItem(
        title: "Server Storage",
        status: .notChecked,
        detail: "Run Test Connection."
      )
    }

    return ProductionReadinessItem(
      title: "Server Storage",
      status: storageIsReady(healthResponse) ? .ready : .warning,
      detail: storageIsReady(healthResponse)
        ? "Transaction, fulfilled, license, activation, and webhook storage are writable."
        : "One or more server storage directories are not writable."
    )
  }

  private var operationsReadinessItem: ProductionReadinessItem {
    guard operationsStatus != nil else {
      return ProductionReadinessItem(
        title: "Operations Status",
        status: .notChecked,
        detail: "Run Refresh Operations."
      )
    }

    return ProductionReadinessItem(
      title: "Operations Status",
      status: .ready,
      detail: "Protected operations endpoint is reachable."
    )
  }

  private var pendingQueueReadinessItem: ProductionReadinessItem {
    guard let operationsStatus else {
      return ProductionReadinessItem(
        title: "Pending Queue",
        status: .notChecked,
        detail: "Run Refresh Operations."
      )
    }

    let pendingCount = operationsStatus.counts.pendingTransactions
    return ProductionReadinessItem(
      title: "Pending Queue",
      status: pendingCount == 0 ? .ready : .warning,
      detail: pendingCount == 0
        ? "No pending transactions are waiting."
        : "\(pendingCount) pending transaction\(pendingCount == 1 ? "" : "s") need review."
    )
  }

  private var webhookReadinessItem: ProductionReadinessItem {
    guard let latestWebhookEvent = operationsStatus?.latest.webhookEvents.first else {
      return ProductionReadinessItem(
        title: "Webhook Intake",
        status: operationsStatus == nil ? .notChecked : .warning,
        detail: operationsStatus == nil ? "Run Refresh Operations." : "No recent webhook events found."
      )
    }

    let isStored = latestWebhookEvent.status.localizedCaseInsensitiveCompare("stored") == .orderedSame
    return ProductionReadinessItem(
      title: "Webhook Intake",
      status: isStored ? .ready : .warning,
      detail: isStored
        ? "Latest webhook event was stored."
        : "Latest webhook event is \(latestWebhookEvent.status): \(latestWebhookEvent.message)."
    )
  }

  private var emailDraftReadinessItem: ProductionReadinessItem {
    let mailURL = URL(string: "mailto:support@updockapp.com")!
    let mailAppURL = NSWorkspace.shared.urlForApplication(toOpen: mailURL)

    return ProductionReadinessItem(
      title: "Email Drafts",
      status: mailAppURL == nil ? .warning : .ready,
      detail: mailAppURL == nil
        ? "No mail app is available for customer draft delivery."
        : "Mail draft handoff is available."
    )
  }

  private func checkConnection() async {
    isCheckingConnection = true
    healthError = nil

    do {
      healthResponse = try await HealthService.shared.checkServer(
        at: settings.healthURL
      )
      lastCheckedAt = Date()
    } catch {
      healthResponse = nil
      lastCheckedAt = Date()
      healthError = error.localizedDescription
    }

    isCheckingConnection = false
  }

  private func runActivationLimitTest() async {
    isRunningActivationTest = true
    activationTestSteps = await ServerService.shared.runActivationLimitTest(
      settings: settings,
      serial: activationTestSerial,
      seatAllowance: 2
    )
    isRunningActivationTest = false
  }

  private func fetchOperationsStatus() async {
    isFetchingOperationsStatus = true
    operationsStatusError = nil

    do {
      operationsStatus = try await ServerService.shared.fetchOperationsStatus(
        settings: settings,
        managerToken: managerToken
      )
      KeychainSettingsStore.shared.managerToken = managerToken
      operationsStatusCheckedAt = Date()
    } catch {
      await retryOperationsStatusWithSavedToken(after: error)
    }

    isFetchingOperationsStatus = false
  }

  private func sendServerEmailTest() async {
    isSendingServerEmailTest = true
    serverEmailTestMessage = ""

    do {
      let response = try await ServerService.shared.sendTestLicenseEmail(
        settings: settings,
        recipient: serverEmailTestRecipient
      )

      let attachment = response.attachment.map { " Attachment: \($0)." } ?? ""
      serverEmailTestMessage = response.sent
        ? "Sent test email to \(response.recipient).\(attachment)"
        : "Server reported that the test email was not sent."
    } catch {
      serverEmailTestMessage = error.localizedDescription
    }

    isSendingServerEmailTest = false
  }

  private func saveManagerToken() {
    KeychainSettingsStore.shared.managerToken = managerToken
    showingManagerTokenSyncAlert = true
  }

  private func updateLocalPrivateConfigManagerToken() {
    if let configURL = savedLocalPrivateConfigURL() {
      _ = updateLocalPrivateConfigManagerToken(at: configURL)
      return
    }

    chooseAndUpdateLocalPrivateConfigManagerToken()
  }

  private func chooseAndUpdateLocalPrivateConfigManagerToken() {
    let configDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Documents/GitHub/UpDockWebPage/updock-private")

    let panel = NSOpenPanel()
    panel.title = "Choose Private Config"
    panel.message = "Select paddle-config.php in updock-private."
    panel.prompt = "Update Config"
    panel.directoryURL = configDirectoryURL
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    if let phpType = UTType(filenameExtension: "php") {
      panel.allowedContentTypes = [phpType]
    }

    guard panel.runModal() == .OK, let configURL = panel.url else {
      managerTokenConfigUpdateMessage = "Local private config was not updated."
      return
    }

    if updateLocalPrivateConfigManagerToken(at: configURL) {
      saveLocalPrivateConfigBookmark(for: configURL)
    }
  }

  private func updateLocalPrivateConfigManagerToken(at configURL: URL) -> Bool {
    do {
      let didAccess = configURL.startAccessingSecurityScopedResource()
      defer {
        if didAccess {
          configURL.stopAccessingSecurityScopedResource()
        }
      }

      var config = try String(contentsOf: configURL, encoding: .utf8)
      let escapedToken = managerToken.replacingOccurrences(of: "'", with: "\\'")
      let pattern = #"const\s+UPDOCK_MANAGER_TOKEN\s*=\s*'[^']*';"#
      let replacement = "const UPDOCK_MANAGER_TOKEN = '\(escapedToken)';"

      guard config.range(of: pattern, options: .regularExpression) != nil else {
        managerTokenConfigUpdateMessage = "Could not find UPDOCK_MANAGER_TOKEN in local private config."
        return false
      }

      config = config.replacingOccurrences(
        of: pattern,
        with: replacement,
        options: .regularExpression
      )

      try config.write(to: configURL, atomically: true, encoding: .utf8)
      managerTokenConfigUpdateMessage = "Updated \(configURL.lastPathComponent). Sync it separately to the server."
      return true
    } catch {
      managerTokenConfigUpdateMessage = "Could not update local private config: \(error.localizedDescription)"
      return false
    }
  }

  private func savedLocalPrivateConfigURL() -> URL? {
    guard let encodedBookmark = UserDefaults.standard.string(forKey: localPrivateConfigBookmarkKey),
          let bookmarkData = Data(base64Encoded: encodedBookmark) else {
      return nil
    }

    do {
      var isStale = false
      let configURL = try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      if isStale {
        UserDefaults.standard.removeObject(forKey: localPrivateConfigBookmarkKey)
        return nil
      }

      return configURL
    } catch {
      UserDefaults.standard.removeObject(forKey: localPrivateConfigBookmarkKey)
      return nil
    }
  }

  private func saveLocalPrivateConfigBookmark(for configURL: URL) {
    do {
      let didAccess = configURL.startAccessingSecurityScopedResource()
      defer {
        if didAccess {
          configURL.stopAccessingSecurityScopedResource()
        }
      }

      let bookmarkData = try configURL.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(
        bookmarkData.base64EncodedString(),
        forKey: localPrivateConfigBookmarkKey
      )
      managerTokenConfigUpdateMessage = "Updated \(configURL.lastPathComponent). Future updates can reuse this file. Sync it separately to the server."
    } catch {
      managerTokenConfigUpdateMessage = "Updated \(configURL.lastPathComponent), but could not remember file access: \(error.localizedDescription)"
    }
  }

  private func retryOperationsStatusWithSavedToken(after firstError: Error) async {
    let savedToken = KeychainSettingsStore.shared.managerToken

    guard case NetworkServiceError.serverError(401) = firstError,
          savedToken != managerToken else {
      operationsStatus = nil
      operationsStatusCheckedAt = Date()
      operationsStatusError = firstError.localizedDescription
      return
    }

    do {
      operationsStatus = try await ServerService.shared.fetchOperationsStatus(
        settings: settings,
        managerToken: savedToken
      )
      managerToken = savedToken
      operationsStatusCheckedAt = Date()
    } catch {
      operationsStatus = nil
      operationsStatusCheckedAt = Date()
      operationsStatusError = error.localizedDescription
    }
  }

  private func storageIsReady(_ healthResponse: HealthResponse) -> Bool {
    healthResponse.transactionsWritable
      && healthResponse.fulfilledWritable
      && (healthResponse.licensesWritable ?? true)
      && (healthResponse.activationsWritable ?? true)
      && (healthResponse.deliveredLicensesWritable ?? true)
      && (healthResponse.webhookLogWritable ?? true)
  }

  private func activationURLRow(_ label: String, _ url: String) -> some View {
    LabeledContent(label) {
      Text(url)
        .font(.caption.monospaced())
        .foregroundStyle(.secondary)
        .textSelection(.enabled)
    }
  }

  private func storageRow(_ label: String, _ isWritable: Bool) -> some View {
    LabeledContent(label) {
      writableLabel(isWritable)
    }
  }

  private func readinessRow(_ item: ProductionReadinessItem) -> some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: readinessSymbol(for: item.status))
        .foregroundStyle(readinessStyle(for: item.status))
        .frame(width: 18)

      VStack(alignment: .leading, spacing: 2) {
        Text(item.title)
          .font(.body.weight(.medium))

        Text(item.detail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .textSelection(.enabled)
      }

      Spacer()
    }
  }

  private func readinessSymbol(for status: ProductionReadinessStatus) -> String {
    switch status {
    case .ready:
      return "checkmark.circle"
    case .warning:
      return "exclamationmark.triangle"
    case .notChecked:
      return "questionmark.circle"
    }
  }

  private func readinessStyle(for status: ProductionReadinessStatus) -> AnyShapeStyle {
    switch status {
    case .ready:
      return AnyShapeStyle(.green)
    case .warning:
      return AnyShapeStyle(.orange)
    case .notChecked:
      return AnyShapeStyle(.secondary)
    }
  }

  private func webhookSymbol(for status: String) -> String {
    switch status.lowercased() {
    case "stored":
      return "tray.and.arrow.down"
    case "warning":
      return "exclamationmark.triangle"
    case "error":
      return "xmark.circle"
    default:
      return "info.circle"
    }
  }

  private func webhookStyle(for status: String) -> AnyShapeStyle {
    switch status.lowercased() {
    case "stored":
      return AnyShapeStyle(.green)
    case "warning":
      return AnyShapeStyle(.orange)
    case "error":
      return AnyShapeStyle(.red)
    default:
      return AnyShapeStyle(.secondary)
    }
  }

  private func copyWebhookEventResults() {
    guard let operationsStatus else {
      return
    }

    let results = operationsStatus.latest.webhookEvents.prefix(5).enumerated().map { index, event in
      var lines = [
        "\(index + 1). \(event.message)",
        "status: \(event.status)"
      ]

      if let time = event.time {
        lines.append("time: \(time)")
      }

      if let context = event.context, !context.isEmpty {
        lines.append(contentsOf: context.sorted(by: { $0.key < $1.key }).map { key, value in
          "\(key): \(value)"
        })
      }

      return lines.joined(separator: "\n")
    }
    .joined(separator: "\n\n")

    copyToPasteboard(results)
  }

  private func copyToPasteboard(_ value: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
  }

  private func writableLabel(_ isWritable: Bool) -> some View {
    Label(
      isWritable ? "Writable" : "Not Writable",
      systemImage: isWritable ? "checkmark.circle" : "xmark.circle"
    )
    .foregroundStyle(isWritable ? AnyShapeStyle(.green) : AnyShapeStyle(.red))
  }
}
