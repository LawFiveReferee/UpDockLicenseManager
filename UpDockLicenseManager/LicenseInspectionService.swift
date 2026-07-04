//
//  LicenseInspectionService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation

enum LicenseInspectionService {
    
    static func inspectLicenseFile(
        at url: URL
    ) throws -> ImportedLicenseInspection {
        
        let data = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let file = try decoder.decode(
            LicenseFile.self,
            from: data
        )
        
        let isValid = try LicenseService.verifyLicenseFile(file)
        
        return ImportedLicenseInspection(
            fileURL: url,
            licenseFile: file,
            isValid: isValid
        )
    }
}
