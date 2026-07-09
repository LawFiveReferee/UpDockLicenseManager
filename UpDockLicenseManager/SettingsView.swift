//
//  SettingsView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/2/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var settings = GeneralSettings()
    
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
            
            Text("Email settings coming next.")
                .padding()
                .tabItem {
                    Label("Email", systemImage: "envelope")
                }
        }
        .frame(width: 620, height: 420)
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
