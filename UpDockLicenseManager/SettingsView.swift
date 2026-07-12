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
    let store: LicenseStore
    let marketingContactStore: MarketingContactStore
    
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

            MarketingContactsView(
                licenseStore: store,
                contactStore: marketingContactStore
            )
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
    @AppStorage("showDevelopmentTools") private var showDevelopmentTools = false
    @Bindable var licenseStore: LicenseStore
    @Bindable var contactStore: MarketingContactStore
    @State private var statusMessage = ""
    @State private var selectedContactIDs: Set<MarketingContact.ID> = []
    @State private var selectedList: MarketingContactList = .proPurchasers
    @State private var isRefreshing = false

    private var contacts: [MarketingContact] {
        switch selectedList {
        case .proPurchasers:
            contactStore.contacts
        case .subscribers:
            contactStore.subscribers
        }
    }

    private var selectedContacts: [MarketingContact] {
        contacts.filter { selectedContactIDs.contains($0.id) }
    }

    private var allContactsSelected: Bool {
        !contacts.isEmpty && selectedContactIDs.isSuperset(of: contacts.map(\.id))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Marketing Contacts")
                    .font(.title3.bold())

                Text("\(contacts.count) \(selectedList.countLabel(for: contacts.count)).")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Copy uses tab-separated rows: Name, Email.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("List", selection: $selectedList) {
                ForEach(MarketingContactList.allCases) { list in
                    Text(list.rawValue).tag(list)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedList) {
                selectedContactIDs = []
                statusMessage = ""
            }

            marketingContactsTable

            HStack {
                Button("Refresh") {
                    Task {
                        await refreshContacts()
                    }
                }
                .disabled(isRefreshing)

                if showDevelopmentTools {
                    Button("Add Sample") {
                        addSampleContact()
                    }
                }

                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button("Delete", role: .destructive) {
                    deleteSelectedContacts()
                }
                .disabled(selectedContactIDs.isEmpty)

                Button("Copy Selected") {
                    copyTSV(selectedContacts)
                }
                .disabled(selectedContactIDs.isEmpty)

                Button("Copy All") {
                    copyTSV(contacts)
                }
                .disabled(contacts.isEmpty)
            }
        }
        .padding()
    }

    private var marketingContactsTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Toggle(
                    "",
                    isOn: Binding(
                        get: { allContactsSelected },
                        set: { isSelected in
                            selectedContactIDs = isSelected ? Set(contacts.map(\.id)) : []
                        }
                    )
                )
                .labelsHidden()
                .disabled(contacts.isEmpty)
                .frame(width: 28)
                .accessibilityLabel("Select all marketing contacts")

                Text("Name")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

                Text("Email")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)

                Text("Last Purchase")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(width: 96, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary)

            Divider()

            if contacts.isEmpty {
                ContentUnavailableView(
                    "No Opt-In Contacts",
                    systemImage: "person.crop.circle.badge.questionmark",
                    description: Text(selectedList.emptyMessage)
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(contacts) { contact in
                            marketingContactRow(contact)
                            Divider()
                        }
                    }
                }
                .frame(minHeight: 220)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary)
        }
    }

    private func marketingContactRow(_ contact: MarketingContact) -> some View {
        HStack(spacing: 12) {
            Toggle(
                "",
                isOn: Binding(
                    get: { selectedContactIDs.contains(contact.id) },
                    set: { isSelected in
                        if isSelected {
                            selectedContactIDs.insert(contact.id)
                        } else {
                            selectedContactIDs.remove(contact.id)
                        }
                    }
                )
            )
            .labelsHidden()
            .frame(width: 28)
            .accessibilityLabel("Select \(contact.name.isEmpty ? contact.email : contact.name)")

            Text(contact.name.isEmpty ? "Unknown Customer" : contact.name)
                .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .textSelection(.enabled)

            Text(contact.email)
                .font(.body.monospaced())
                .foregroundStyle(.secondary)
                .frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .textSelection(.enabled)

            Text(formattedPurchaseDate(contact.latestPurchaseAt))
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
                .lineLimit(1)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(selectedContactIDs.contains(contact.id) ? Color.accentColor.opacity(0.12) : Color.clear)
    }

    private func refreshContacts() async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        licenseStore.reloadFromDisk()
        contactStore.reloadFromDisk()
        let purchaserResult = contactStore.importOptedIn(from: licenseStore.licenses)
        var subscriberResult = MarketingContactImportResult(addedCount: 0, updatedCount: 0)
        var subscriberError = ""

        do {
            let settings = NetworkSettings()
            let managerToken = KeychainSettingsStore.shared.managerToken
            let response = try await ServerService.shared.fetchMarketingSubscribers(
                settings: settings,
                managerToken: managerToken
            )
            subscriberResult = contactStore.importSubscribers(response.subscribers)

            let unsubscribedResponse = try await ServerService.shared.fetchMarketingUnsubscribed(
                settings: settings,
                managerToken: managerToken
            )
            contactStore.applyUnsubscribed(unsubscribedResponse.unsubscribed)
        } catch {
            subscriberError = error.localizedDescription
        }

        selectedContactIDs = []

        if !subscriberError.isEmpty {
            statusMessage = "Reloaded purchasers. Subscriber sync failed: \(subscriberError)"
        } else {
            statusMessage = selectedList == .proPurchasers
                ? refreshStatus(prefix: "Purchasers", result: purchaserResult)
                : refreshStatus(prefix: "Subscribers", result: subscriberResult)
        }
    }

    private func copyTSV(_ contactsToCopy: [MarketingContact]) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(MarketingContact.tsv(from: contactsToCopy), forType: .string)
        statusMessage = "Copied \(contactsToCopy.count) opted-in \(contactsToCopy.count == 1 ? "contact" : "contacts")."
    }

    private func addSampleContact() {
        switch selectedList {
        case .proPurchasers:
            contactStore.addSampleContact()
        case .subscribers:
            contactStore.addSampleSubscriber()
        }

        selectedContactIDs = []
        statusMessage = "Added sample marketing contact."
    }

    private func formattedPurchaseDate(_ date: Date?) -> String {
        guard let date else {
            return "—"
        }

        return date.formatted(.dateTime.month().day().year())
    }

    private func deleteSelectedContacts() {
        let selectedKeys = selectedContactIDs

        guard !selectedKeys.isEmpty else {
            return
        }

        if selectedList == .proPurchasers {
            for index in licenseStore.licenses.indices {
                let licenseKey = MarketingContact.id(
                    name: licenseStore.licenses[index].name,
                    email: licenseStore.licenses[index].email
                )

                if selectedKeys.contains(licenseKey) {
                    licenseStore.licenses[index].paddleMarketingConsent = false
                }
            }
        }

        switch selectedList {
        case .proPurchasers:
            contactStore.delete(ids: selectedKeys)
        case .subscribers:
            contactStore.deleteSubscribers(ids: selectedKeys)
        }

        let deletedCount = selectedContactIDs.count
        selectedContactIDs = []
        statusMessage = "Removed \(deletedCount) \(deletedCount == 1 ? "contact" : "contacts") from the Marketing list."
    }

    private func refreshStatus(prefix: String, result: MarketingContactImportResult) -> String {
        result.changedCount == 0
            ? "Reloaded \(prefix.lowercased())."
            : "\(prefix): added \(result.addedCount), updated \(result.updatedCount)."
    }
}

private enum MarketingContactList: String, CaseIterable, Identifiable {
    case proPurchasers = "Pro Purchasers"
    case subscribers = "Subscribers"

    var id: String {
        rawValue
    }

    var emptyMessage: String {
        switch self {
        case .proPurchasers:
            "Contacts appear here after synced Paddle purchases include marketing consent."
        case .subscribers:
            "Contacts appear here after website visitors subscribe to UpDock updates."
        }
    }

    func countLabel(for count: Int) -> String {
        switch self {
        case .proPurchasers:
            return "opted-in \(count == 1 ? "Pro purchaser" : "Pro purchasers")"
        case .subscribers:
            return "\(count == 1 ? "subscriber" : "subscribers")"
        }
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
