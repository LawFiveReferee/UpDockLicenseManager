//
//  ImportedLicenseInspection.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation

struct ImportedLicenseInspection: Identifiable {
    let id = UUID()
    let fileURL: URL
    let licenseFile: LicenseFile
    let isValid: Bool
    
    var title: String {
        licenseFile.license.name.isEmpty
        ? licenseFile.license.serial
        : licenseFile.license.name
    }
    
    var statusText: String {
        isValid ? "Signature Valid" : "Signature Invalid"
    }
}

