//
//  LicenseInspectionView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseInspectionView: View {
    @Environment(\.dismiss) private var dismiss
    let inspection: ImportedLicenseInspection

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("License File Inspection")
                    .font(.title2.bold())
                
                Spacer()
                
                Text(inspection.isValid ? "✓ Valid" : "⚠︎ Invalid")
                    .font(.headline)
                    .foregroundStyle(inspection.isValid ? .green : .red)
            }
            
            Divider()
            
            Group {
                row("File", inspection.fileURL.lastPathComponent)
                row("File Type", inspection.licenseFile.fileType)
                row("Format Version", "\(inspection.licenseFile.formatVersion)")
                row("Created By", inspection.licenseFile.createdBy)
                row("Created At", inspection.licenseFile.createdAt.formatted(date: .abbreviated, time: .shortened))
                row("Signing Identity", inspection.licenseFile.signingIdentity)
                row("Signature Algorithm", inspection.licenseFile.signatureAlgorithm)
                row("Signature", inspection.licenseFile.signature == nil ? "Missing" : "Present")
            }
            
            Divider()
            
            Text("License")
                .font(.headline)
            
            Group {
                row("Serial", inspection.licenseFile.license.serial)
                row("Type", inspection.licenseFile.license.type.rawValue)
                row("Product", inspection.licenseFile.license.product)
                row("Name", inspection.licenseFile.license.name)
                row("Email", inspection.licenseFile.license.email)
                row("Issued", inspection.licenseFile.license.issuedAt.formatted(date: .abbreviated, time: .shortened))
                
                if let expiresAt = inspection.licenseFile.license.expiresAt {
                    row("Expires", expiresAt.formatted(date: .abbreviated, time: .omitted))
                } else {
                    row("Expires", "Never")
                }
            }
            
            HStack {
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
            }
        }
        .padding(24)
        .frame(width: 560)
    }
    
    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            
            Text(value.isEmpty ? "—" : value)
                .textSelection(.enabled)
        }
    }
}

