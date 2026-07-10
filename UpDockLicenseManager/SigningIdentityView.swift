//
//  SigningIdentityView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct SigningIdentityView: View {
    @State private var publicKeyBase64 = ""
    @State private var errorMessage: String?
    @State private var statusMessage = ""
    @State private var showingServerKeyConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Signing Identity")
                .font(.headline)
            
            Text("Stockly Consulting")
                .font(.title3.bold())
            
            Text("Private key stored securely in macOS Keychain.")
                .foregroundStyle(.secondary)
            
            Text("Public Key")
                .font(.subheadline.bold())
            
            Text(publicKeyBase64.isEmpty ? "Unavailable" : publicKeyBase64)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            Button("Copy Public Key") {
                copyPublicKey()
            }
            .disabled(publicKeyBase64.isEmpty)
            
            Button("Export Swift File…") {
                exportSwiftFile()
            }
            .disabled(publicKeyBase64.isEmpty)

            Divider()

            Text("Server Automation")
                .font(.subheadline.bold())

            Text("Copies the private signing key as a PHP config line for updock-private/paddle-config.php. Only use this on the private server configuration.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Copy Server Signing Config Line…", systemImage: "key.fill") {
                showingServerKeyConfirmation = true
            }
            .disabled(publicKeyBase64.isEmpty)
            
            Button("Refresh") {
                loadPublicKey()
            }
            
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .padding(18)
        .frame(maxWidth: 700, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear {
            loadPublicKey()
        }
        .alert("Copy Private Signing Key?", isPresented: $showingServerKeyConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Copy Config Line") {
                copyServerSigningConfigLine()
            }
        } message: {
            Text("This copies the private license signing key to the clipboard. Paste it only into the private server paddle-config.php file, then clear the clipboard when finished.")
        }
    }
    
    private func loadPublicKey() {
        do {
            publicKeyBase64 = try SigningIdentityStore.publicKeyBase64()
            errorMessage = nil
        } catch {
            publicKeyBase64 = ""
            errorMessage = error.localizedDescription
        }
    }
    
    private func exportSwiftFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "swift") ?? .plainText
        ]
        panel.nameFieldStringValue = "UpDockLicensePublicKey.swift"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try SigningIdentityStore.exportPublicKeySwiftFile(to: url)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func copyPublicKey() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(publicKeyBase64, forType: .string)
    }

    private func copyServerSigningConfigLine() {
        do {
            let configLine = try SigningIdentityStore.serverAutomationPrivateKeyConfigLine()
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(configLine, forType: .string)
            statusMessage = "Copied private signing config line. Paste it into updock-private/paddle-config.php, sync privately, then clear the clipboard."
            errorMessage = nil
        } catch {
            statusMessage = ""
            errorMessage = error.localizedDescription
        }
    }
}
