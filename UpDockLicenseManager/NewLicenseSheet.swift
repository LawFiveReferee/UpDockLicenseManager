//
//  NewLicenseSheet.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct NewLicenseSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var type: UpDockLicenseType = .beta
    @State private var name = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var expiresAt = Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date()
    
    let onCreate: (LicenseRecord) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Create UpDock Pro License")
                .font(.title2.bold())
            
            Picker("License Type", selection: $type) {
                Text("Beta").tag(UpDockLicenseType.beta)
                Text("Trial").tag(UpDockLicenseType.trial)
                Text("Commercial").tag(UpDockLicenseType.commercial)
            }
            .pickerStyle(.segmented)
            
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
            
            if type == .beta || type == .trial {
                DatePicker("Expires", selection: $expiresAt, displayedComponents: .date)
            }
            
            TextField("Notes", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Create License") {
                    createLicense()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 460)
    }
    
    private func createLicense() {
        let license = LicenseService.createLicense(
            type: type,
            name: name,
            email: email,
            expiresAt: (type == .beta || type == .trial) ? expiresAt : nil,
            notes: notes
        )
        
        onCreate(license)
        dismiss()
    }
}
