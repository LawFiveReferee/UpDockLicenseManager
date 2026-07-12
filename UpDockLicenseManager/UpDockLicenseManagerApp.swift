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

  var body: some Scene {
    WindowGroup {
      ContentView(store: licenseStore)
    }
    
    Settings {
      SettingsView(store: licenseStore)
    }
  }
}
