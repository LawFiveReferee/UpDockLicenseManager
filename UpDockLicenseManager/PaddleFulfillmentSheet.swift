//
//  PaddleFulfillmentSheet.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct PaddleFulfillmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var customerName = ""
    @State private var customerEmail = ""
    @State private var paddleCustomerID = ""
    @State private var paddleTransactionID = ""
    @State private var paddleProductID = ""
    @State private var paddlePriceID = ""
    @State private var paddleStatus = "completed"
    @State private var notes = ""
    @State private var duplicateLicense: LicenseRecord?
    
    let existingLicenseForTransactionID: (String) -> LicenseRecord?
    let onCreate: (LicenseRecord) -> Void
    let onShowExisting: (LicenseRecord) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Fulfill Paddle Purchase")
                .font(.title2.bold())
            
            Text("Creates a non-expiring UpDock Pro commercial license.")
                .foregroundStyle(.secondary)
            
            Form {
                Section("Customer") {
                    TextField("Name", text: $customerName)
                    TextField("Email", text: $customerEmail)
                }
                
                Section("Paddle") {
                    TextField("Customer ID", text: $paddleCustomerID)
                    TextField("Transaction ID", text: $paddleTransactionID)
                    TextField("Product ID", text: $paddleProductID)
                    TextField("Price ID", text: $paddlePriceID)
                    TextField("Status", text: $paddleStatus)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Create Commercial License") {
                    createLicense()
                }
                .buttonStyle(.borderedProminent)
                .disabled(customerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .alert("Paddle Transaction Already Fulfilled", isPresented: Binding(
                    get: { duplicateLicense != nil },
                    set: { if !$0 { duplicateLicense = nil } }
                )) {
                    Button("Show Existing") {
                        if let duplicateLicense {
                            onShowExisting(duplicateLicense)
                        }
                        duplicateLicense = nil
                        dismiss()
                    }
                    
                    Button("Cancel", role: .cancel) {
                        duplicateLicense = nil
                    }
                } message: {
                    if let duplicateLicense {
                        Text("This Paddle transaction is already associated with \(duplicateLicense.serial).")
                    } else {
                        Text("This Paddle transaction has already been fulfilled.")
                    }
                }
                
            }
        }
        .padding(24)
        .frame(width: 560, height: 620)
    }
    
    private func createLicense() {
        let email = customerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let transactionID = paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let existing = existingLicenseForTransactionID(transactionID) {
            duplicateLicense = existing
            return
        }
        
        let license = LicenseRecord(
            serial: LicenseGenerator.makeSerial(type: .commercial),
            type: .commercial,
            name: customerName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email,
            expiresAt: nil,
            notes: notes,
            paddleCustomerID: paddleCustomerID.trimmingCharacters(in: .whitespacesAndNewlines),
            paddleTransactionID: transactionID,
            paddleEmail: email,
            paddleProductID: paddleProductID.trimmingCharacters(in: .whitespacesAndNewlines),
            paddlePriceID: paddlePriceID.trimmingCharacters(in: .whitespacesAndNewlines),
            paddleStatus: paddleStatus.trimmingCharacters(in: .whitespacesAndNewlines),
            fulfilledAt: Date()
        )
        
        onCreate(license)
        dismiss()
    }
}
