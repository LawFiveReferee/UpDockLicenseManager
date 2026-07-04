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
            
            Button("Refresh") {
                loadPublicKey()
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
}
