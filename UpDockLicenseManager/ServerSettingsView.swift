//
//  ServerSettingsView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import AppKit
import SwiftUI

struct ServerSettingsView: View {
  @State private var settings = NetworkSettings()
  @State private var managerToken = KeychainSettingsStore.shared.managerToken
  @State private var showingToken = false
  @State private var healthResponse: HealthResponse?
  @State private var healthError: String?
  @State private var lastCheckedAt: Date?
  @State private var isCheckingConnection = false

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
            KeychainSettingsStore.shared.managerToken = managerToken
          }

          Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(
              managerToken,
              forType: .string
            )
          }

          Button("Save") {
            KeychainSettingsStore.shared.managerToken = managerToken
          }
          .buttonStyle(.borderedProminent)
        }

        Text("Used by License Manager when communicating with pending.php and fulfilled.php.")
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
        }

        if let healthError {
          Label(healthError, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
        }
      }
    }
    .formStyle(.grouped)
    .padding()
  }

  private var connectionStatusTitle: String {
    guard let healthResponse else {
      return "Not Checked"
    }

    guard healthResponse.transactionsWritable && healthResponse.fulfilledWritable else {
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

    return healthResponse.transactionsWritable && healthResponse.fulfilledWritable
      ? "checkmark.circle"
      : "exclamationmark.triangle"
  }

  private var connectionStatusStyle: AnyShapeStyle {
    guard let healthResponse else {
      return AnyShapeStyle(.secondary)
    }

    return healthResponse.transactionsWritable && healthResponse.fulfilledWritable
      ? AnyShapeStyle(.green)
      : AnyShapeStyle(.orange)
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

  private func writableLabel(_ isWritable: Bool) -> some View {
    Label(
      isWritable ? "Writable" : "Not Writable",
      systemImage: isWritable ? "checkmark.circle" : "xmark.circle"
    )
    .foregroundStyle(isWritable ? AnyShapeStyle(.green) : AnyShapeStyle(.red))
  }
}
