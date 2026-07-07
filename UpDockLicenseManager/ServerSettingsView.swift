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

struct ServerSettingsView: View {
  @State private var settings = NetworkSettings()
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
          storageRow("Activations", operationsStatus.storage.activationsWritable)
          storageRow("Webhook Log", operationsStatus.storage.webhookLogWritable)

          if !operationsStatus.latest.webhookEvents.isEmpty {
            Divider()

            Text("Recent Webhook Events")
              .font(.headline)

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
              }
            }
          }
        }

        if let operationsStatusError {
          Label(operationsStatusError, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
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
