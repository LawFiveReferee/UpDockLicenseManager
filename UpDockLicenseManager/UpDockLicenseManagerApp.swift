//
//  UpDockLicenseManagerApp.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

@main
struct UpDockLicenseManagerApp: App {
  @State private var licenseStore = LicenseStore()
  @State private var marketingContactStore = MarketingContactStore()

  var body: some Scene {
    WindowGroup {
      ContentView(
        store: licenseStore,
        marketingContactStore: marketingContactStore
      )
    }
    
    Settings {
      SettingsView(
        store: licenseStore,
        marketingContactStore: marketingContactStore
      )
    }
  }
}
