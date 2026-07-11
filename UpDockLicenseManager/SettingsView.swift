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
    @State private var licenseStore = LicenseStore()
    
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

            MarketingContactsView(store: licenseStore)
                .tabItem {
                    Label("Marketing", systemImage: "person.crop.circle.badge.checkmark")
                }

            LaunchChecklistView()
                .tabItem {
                    Label("Launch", systemImage: "checklist")
                }
        }
        .frame(width: 680, height: 500)
    }
}

struct MarketingContactsView: View {
    @Bindable var store: LicenseStore
    @State private var statusMessage = ""

    private var contacts: [MarketingContact] {
        MarketingContact.make(from: store.licenses)
    }

    var body: some View {
        Form {
            Section("Opt-In Contacts") {
                LabeledContent("Contacts") {
                    Text("\(contacts.count)")
                }

                HStack {
                    Button("Refresh") {
                        store.licenses = LicenseStore().licenses
                        statusMessage = "Reloaded local licenses."
                    }

                    Button("Copy CSV") {
                        copyCSV()
                    }
                    .disabled(contacts.isEmpty)
                }

                Text("Only purchasers with Paddle marketing consent are included.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !contacts.isEmpty {
                Section("Contacts") {
                    ForEach(contacts) { contact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contact.name.isEmpty ? "Unknown Customer" : contact.name)
                                .font(.headline)

                            Text(contact.email)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)

                            if !contact.paddleCustomerID.isEmpty {
                                Text(contact.paddleCustomerID)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func copyCSV() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(MarketingContact.csv(from: contacts), forType: .string)
        statusMessage = "Copied \(contacts.count) opted-in \(contacts.count == 1 ? "contact" : "contacts")."
    }
}

struct MarketingContact: Identifiable, Hashable {
    var email: String
    var name: String
    var paddleCustomerID: String
    var latestPurchaseAt: Date?

    var id: String {
        email.lowercased()
    }

    static func make(from licenses: [LicenseRecord]) -> [MarketingContact] {
        var contactsByEmail: [String: MarketingContact] = [:]

        for license in licenses where license.paddleMarketingConsent {
            let email = license.email.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !email.isEmpty else {
                continue
            }

            let key = email.lowercased()
            let existing = contactsByEmail[key]
            let latestPurchaseAt = [existing?.latestPurchaseAt, license.fulfilledAt, license.issuedAt]
                .compactMap { $0 }
                .max()

            contactsByEmail[key] = MarketingContact(
                email: email,
                name: preferred(existing?.name, license.name),
                paddleCustomerID: preferred(existing?.paddleCustomerID, license.paddleCustomerID),
                latestPurchaseAt: latestPurchaseAt
            )
        }

        return contactsByEmail.values.sorted {
            $0.email.localizedCaseInsensitiveCompare($1.email) == .orderedAscending
        }
    }

    static func csv(from contacts: [MarketingContact]) -> String {
        let rows = contacts.map { contact in
            [
                csvEscape(contact.email),
                csvEscape(contact.name),
                csvEscape(contact.paddleCustomerID),
                csvEscape(contact.latestPurchaseAt?.formatted(.iso8601) ?? "")
            ].joined(separator: ",")
        }

        return (["Email,Name,Paddle Customer ID,Latest Purchase At"] + rows).joined(separator: "\n")
    }

    private static func preferred(_ existing: String?, _ replacement: String) -> String {
        let existingValue = existing?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let replacementValue = replacement.trimmingCharacters(in: .whitespacesAndNewlines)

        return existingValue.isEmpty ? replacementValue : existingValue
    }

    private static func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
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
                Toggle("Show development tools", isOn: $settings.showDevelopmentTools)
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
                Toggle("Live discounted checkout test passed", isOn: $liveDiscountTest)
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
            manualSummary("Live discounted checkout test passed", liveDiscountTest),
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
