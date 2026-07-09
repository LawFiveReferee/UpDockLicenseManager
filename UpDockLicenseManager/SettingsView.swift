//
//  SettingsView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/2/26.
//

import SwiftUI
import Observation
import AppKit

struct SettingsView: View {
    @State private var settings = GeneralSettings()
    @State private var emailSettings = EmailSettings()
    
    var body: some View {
        TabView {
            GeneralSettingsView(settings: settings)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            SigningSettingsView()
                .tabItem {
                    Label("Signing", systemImage: "checkmark.seal")
                }
            
            PaddleSettingsView()
                .tabItem {
                    Label("Paddle", systemImage: "creditcard")
                }
            
            ServerSettingsView()
                .tabItem {
                    Label("Server", systemImage: "server.rack")
                }
            
            EmailSettingsView(settings: emailSettings)
                .tabItem {
                    Label("Email", systemImage: "envelope")
                }

            LaunchChecklistView()
                .tabItem {
                    Label("Launch", systemImage: "checklist")
                }
        }
        .frame(width: 680, height: 500)
    }
}

@Observable
final class EmailSettings {
    var preferredFromAddress: String {
        didSet { save() }
    }

    var signatureName: String {
        didSet { save() }
    }

    var signatureEmail: String {
        didSet { save() }
    }

    var signatureURL: String {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    init() {
        self.preferredFromAddress = defaults.string(forKey: "emailPreferredFromAddress") ?? "customerservice@updockapp.com"
        self.signatureName = defaults.string(forKey: "emailSignatureName") ?? "UpDock Customer Service"
        self.signatureEmail = defaults.string(forKey: "emailSignatureEmail") ?? "customerservice@updockapp.com"
        self.signatureURL = defaults.string(forKey: "emailSignatureURL") ?? "https://updockapp.com/pro.html"
    }

    private func save() {
        defaults.set(preferredFromAddress, forKey: "emailPreferredFromAddress")
        defaults.set(signatureName, forKey: "emailSignatureName")
        defaults.set(signatureEmail, forKey: "emailSignatureEmail")
        defaults.set(signatureURL, forKey: "emailSignatureURL")
    }
}

struct EmailSettingsView: View {
    @Bindable var settings: EmailSettings
    @State private var testDraftStatus = ""
    @State private var isPreparingTestDraft = false

    var body: some View {
        Form {
            Section("Mail Drafts") {
                TextField("Preferred From Account", text: $settings.preferredFromAddress)
                Text("Mail drafts open in Apple Mail. The app will try to select this sender account; confirm it before sending.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    prepareTestDraft()
                } label: {
                    if isPreparingTestDraft {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Prepare Test Draft", systemImage: "envelope.badge")
                    }
                }
                .disabled(isPreparingTestDraft)

                if !testDraftStatus.isEmpty {
                    Text(testDraftStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            Section("Signature Links") {
                TextField("Customer Service Email", text: $settings.signatureEmail)
                TextField("UpDock Pro URL", text: $settings.signatureURL)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func prepareTestDraft() {
        isPreparingTestDraft = true
        testDraftStatus = ""

        do {
            try LicenseEmailService.openTestMailDraft(settings: settings)
            testDraftStatus = "Prepared test draft. Confirm the From account, signature links, and test attachment in Mail."
        } catch {
            testDraftStatus = error.localizedDescription
        }

        isPreparingTestDraft = false
    }
}

struct GeneralSettingsView: View {
    @Bindable var settings: GeneralSettings
    
    var body: some View {
        Form {
            Section("General") {
                TextField("Organization", text: $settings.organizationName)
                TextField("Product Name", text: $settings.productName)
                TextField("Support Email", text: $settings.supportEmail)
            }
            
            Section("Defaults") {
                Stepper(
                    "Default Trial Length: \(settings.defaultTrialLengthDays) days",
                    value: $settings.defaultTrialLengthDays,
                    in: 1...365
                )
                
                Stepper(
                    "Default Beta Length: \(settings.defaultBetaLengthDays) days",
                    value: $settings.defaultBetaLengthDays,
                    in: 1...365
                )
            }

            Section("Interface") {
                Toggle("Show text labels in the main toolbar", isOn: $settings.showToolbarTextLabels)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct LaunchChecklistView: View {
    @State private var paddleSettings = PaddleSettings()
    @State private var networkSettings = NetworkSettings()
    @State private var emailSettings = EmailSettings()
    @AppStorage("launchChecklist.domainApproved") private var domainApproved = false
    @AppStorage("launchChecklist.businessVerified") private var businessVerified = false
    @AppStorage("launchChecklist.liveSiteDeployed") private var liveSiteDeployed = false
    @AppStorage("launchChecklist.webhookOneEvent") private var webhookOneEvent = false
    @AppStorage("launchChecklist.liveDiscountTest") private var liveDiscountTest = false
    @AppStorage("launchChecklist.pendingPurchaseVerified") private var pendingPurchaseVerified = false
    @AppStorage("launchChecklist.fulfillmentVerified") private var fulfillmentVerified = false
    @AppStorage("launchChecklist.emailDraftVerified") private var emailDraftVerified = false
    @State private var copyStatus = ""

    private var automaticChecks: [LaunchChecklistItem] {
        [
            LaunchChecklistItem(
                title: "Paddle environment is Production",
                detail: paddleSettings.environment.rawValue,
                isComplete: paddleSettings.environment == .production
            ),
            LaunchChecklistItem(
                title: "Client-side token is live",
                detail: redactedPrefix(paddleSettings.clientSideToken, expectedPrefix: "live_"),
                isComplete: paddleSettings.clientSideToken.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("live_")
            ),
            LaunchChecklistItem(
                title: "Default live Price ID is set",
                detail: paddleSettings.defaultPriceID.isEmpty ? "Not set" : paddleSettings.defaultPriceID,
                isComplete: !paddleSettings.defaultPriceID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ),
            LaunchChecklistItem(
                title: "Server base URL is live",
                detail: networkSettings.serverBaseURL,
                isComplete: networkSettings.serverBaseURL.trimmingCharacters(in: .whitespacesAndNewlines) == "https://updockapp.com/paddle"
            ),
            LaunchChecklistItem(
                title: "Manager token is saved",
                detail: KeychainSettingsStore.shared.managerToken.isEmpty ? "Not saved" : "Saved in Keychain",
                isComplete: !KeychainSettingsStore.shared.managerToken.isEmpty
            ),
            LaunchChecklistItem(
                title: "Customer service sender is set",
                detail: emailSettings.preferredFromAddress,
                isComplete: emailSettings.preferredFromAddress.trimmingCharacters(in: .whitespacesAndNewlines) == "customerservice@updockapp.com"
            )
        ]
    }

    var body: some View {
        Form {
            Section("Automatic Checks") {
                ForEach(automaticChecks) { item in
                    launchStatusRow(item)
                }
            }

            Section("Manual Launch Confirmations") {
                Toggle("Paddle checkout domain is approved", isOn: $domainApproved)
                Toggle("Paddle business and identity verification is complete", isOn: $businessVerified)
                Toggle("Live website is deployed at updockapp.com", isOn: $liveSiteDeployed)
                Toggle("Webhook destination subscribes only to transaction.completed", isOn: $webhookOneEvent)
                Toggle("Live 100% discount checkout test passed", isOn: $liveDiscountTest)
                Toggle("Pending Purchases received the live test purchase", isOn: $pendingPurchaseVerified)
                Toggle("Fulfillment created the expected license and archived the transaction", isOn: $fulfillmentVerified)
                Toggle("License email draft was verified in Apple Mail", isOn: $emailDraftVerified)
            }

            Section("Summary") {
                Button("Copy Launch Checklist Summary", systemImage: "doc.on.doc") {
                    copySummary()
                }

                if !copyStatus.isEmpty {
                    Text(copyStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func launchStatusRow(_ item: LaunchChecklistItem) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: item.isComplete ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(item.isComplete ? Color.green : Color.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                Text(item.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private func copySummary() {
        let lines = automaticChecks.map { item in
            "\(item.isComplete ? "PASS" : "CHECK"): \(item.title) — \(item.detail)"
        } + [
            manualSummary("Paddle checkout domain approved", domainApproved),
            manualSummary("Business and identity verification complete", businessVerified),
            manualSummary("Live website deployed", liveSiteDeployed),
            manualSummary("Webhook limited to transaction.completed", webhookOneEvent),
            manualSummary("Live 100% discount checkout test passed", liveDiscountTest),
            manualSummary("Pending purchase verified", pendingPurchaseVerified),
            manualSummary("Fulfillment verified", fulfillmentVerified),
            manualSummary("License email draft verified", emailDraftVerified)
        ]

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(lines.joined(separator: "\n"), forType: .string)
        copyStatus = "Copied launch checklist summary."
    }

    private func manualSummary(_ title: String, _ isComplete: Bool) -> String {
        "\(isComplete ? "PASS" : "CHECK"): \(title)"
    }

    private func redactedPrefix(_ value: String, expectedPrefix: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return "Not set"
        }

        guard trimmed.hasPrefix(expectedPrefix) else {
            return "Does not start with \(expectedPrefix)"
        }

        return "\(expectedPrefix)…"
    }
}

struct LaunchChecklistItem: Identifiable {
    var id: String { title }
    var title: String
    var detail: String
    var isComplete: Bool
}
