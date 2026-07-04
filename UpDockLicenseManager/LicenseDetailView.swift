//
//  LicenseDetailView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseDetailView: View {
    @State private var editableLicense: LicenseRecord
    @State private var originalLicense: LicenseRecord
    
    let onSave: (LicenseRecord) -> Void
    let onCopySerial: () -> Void
    let onRevoke: () -> Void
    
    init(
        license: LicenseRecord,
        onSave: @escaping (LicenseRecord) -> Void,
        onCopySerial: @escaping () -> Void,
        onRevoke: @escaping () -> Void
    ) {
        self._editableLicense = State(initialValue: license)
        self._originalLicense = State(initialValue: license)
        self.onSave = onSave
        self.onCopySerial = onCopySerial
        self.onRevoke = onRevoke
    }
    
    private var hasUnsavedChanges: Bool {
        editableLicense != originalLicense
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                card {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("License")
                                .font(.title2.bold())
                            
                            Spacer()
                            
                            Text("\(editableLicense.status.symbol) \(editableLicense.status.rawValue)")
                                .font(.headline)
                        }
                        
                        Text(editableLicense.serial)
                            .font(.system(.title3, design: .monospaced))
                            .textSelection(.enabled)
                        
                        HStack {
                            Button("Copy Serial") {
                                onCopySerial()
                            }
                            
                            Button(hasUnsavedChanges ? "Save Changes" : "Saved") {
                                saveChanges()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!hasUnsavedChanges)
                            
                            Button("Revert") {
                                editableLicense = originalLicense
                            }
                            .disabled(!hasUnsavedChanges)
                            
                            Button("Revoke", role: .destructive) {
                                onRevoke()
                            }
                            .disabled(editableLicense.isRevoked)
                        }
                    }
                }
                
                card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Customer / Tester")
                            .font(.headline)
                        
                        TextField("Name", text: $editableLicense.name)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Email", text: $editableLicense.email)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("License Details")
                            .font(.headline)
                        
                        Picker("Type", selection: $editableLicense.type) {
                            ForEach(UpDockLicenseType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 320)
                        
                        DatePicker(
                            "Issued",
                            selection: $editableLicense.issuedAt,
                            displayedComponents: [.date]
                        )
                        
                        if editableLicense.type == .beta || editableLicense.type == .trial {
                            DatePicker(
                                "Expires",
                                selection: Binding(
                                    get: {
                                        editableLicense.expiresAt ?? Date()
                                    },
                                    set: {
                                        editableLicense.expiresAt = $0
                                    }
                                ),
                                displayedComponents: [.date]
                            )
                        }
                    }
                }
                
                card {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Notes")
                            .font(.headline)
                        
                        TextField("Notes", text: $editableLicense.notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(4...8)
                    }
                }
            }
            .padding(24)
        }
        .id(originalLicense.id)
    }
    
    private func saveChanges() {
        onSave(editableLicense)
        originalLicense = editableLicense
    }
    
    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(18)
        .frame(maxWidth: 650, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
