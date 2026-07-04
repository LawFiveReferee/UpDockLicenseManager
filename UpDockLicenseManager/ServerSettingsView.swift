//
//  ServerSettingsView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import SwiftUI

struct ServerSettingsView: View {
    
    @State private var settings = NetworkSettings()
    
    @State private var managerToken =
    KeychainSettingsStore.shared.managerToken
    
    @State private var showingToken = false
    
    var body: some View {
        
        Form {
            
            Section("Server") {
                
                TextField(
                    "Base URL",
                    text: $settings.serverBaseURL
                )
                .textFieldStyle(.roundedBorder)
                
                Text(settings.healthURL)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                
                Text(settings.pendingURL)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                
                Text(settings.fulfilledURL)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                
                Text(settings.webhookURL)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Divider()
                
                Text("Authenticated Pending URL")
                    .font(.headline)
                
                Text(settings.authenticatedPendingURL)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                
                Button("Copy Pending URL") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(
                        settings.authenticatedPendingURL,
                        forType: .string
                    )
                }
                .disabled(managerToken.isEmpty)
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
                        KeychainSettingsStore.shared.managerToken =
                        managerToken
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Text("""
Used by License Manager when communicating with pending.php and fulfilled.php.
""")
                .foregroundStyle(.secondary)
            }
            
            Section("Connection") {
                
                Button("Test Connection") {
                    
                    // next step
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
