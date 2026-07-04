//
//  SigningSettingsView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/2/26.
//

import SwiftUI

struct SigningSettingsView: View {
    var body: some View {
        Form {
            Section("Signing Identity") {
                SigningIdentityView()
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
