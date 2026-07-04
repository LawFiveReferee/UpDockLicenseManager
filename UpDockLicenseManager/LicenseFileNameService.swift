//
//  LicenseFileNameService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation

enum LicenseFileNameService {
    static func suggestedLicenseFileName(for license: LicenseRecord) -> String {
        let baseName: String
        
        if !license.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseName = license.name
        } else if !license.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            baseName = license.email
        } else {
            baseName = license.serial
        }
        
        let cleaned = baseName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        
        return "\(cleaned).updocklicense"
    }
}

