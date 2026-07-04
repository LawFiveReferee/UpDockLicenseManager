//
//  UpDockLicenseManagerApp.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

@main
struct UpDockLicenseManagerApp: App {
       var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        Settings {
            SettingsView()
        }
    }
}
