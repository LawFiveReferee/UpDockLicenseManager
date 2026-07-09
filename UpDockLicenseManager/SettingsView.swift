//
//  SettingsView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/2/26.
//

import SwiftUI
import Observation

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
        }
        .frame(width: 620, height: 420)
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
