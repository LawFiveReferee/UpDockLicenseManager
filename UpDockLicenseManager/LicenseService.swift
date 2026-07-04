//
//  LicenseService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import AppKit
import Foundation
import CryptoKit

enum LicenseService {
    static func createLicense(
        type: UpDockLicenseType,
        name: String,
        email: String,
        expiresAt: Date?,
        notes: String
    ) -> LicenseRecord {
        LicenseRecord(
            serial: LicenseGenerator.makeSerial(type: type),
            type: type,
            name: name,
            email: email,
            expiresAt: expiresAt,
            notes: notes
        )
    }
    
    static func duplicateLicense(_ license: LicenseRecord) -> LicenseRecord {
        LicenseRecord(
            serial: LicenseGenerator.makeSerial(type: license.type),
            type: license.type,
            product: license.product,
            name: license.name,
            email: license.email,
            issuedAt: Date(),
            expiresAt: license.expiresAt,
            notes: license.notes,
            isRevoked: false
        )
    }
    
    static func revokeLicense(_ license: LicenseRecord) -> LicenseRecord {
        var updated = license
        updated.isRevoked = true
        return updated
    }
    
    static func copySerial(_ serial: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(serial, forType: .string)
    }
    static func signedLicenseFile(from record: LicenseRecord) throws -> LicenseFile {
        let portableLicense = UpDockLicense(record: record)
        
        let licenseData = try LicenseSigningService.canonicalLicenseData(portableLicense)
        
        let privateKey = try SigningIdentityStore.loadOrCreatePrivateKey()
        
        let signatureData = try LicenseSigningService.sign(
            data: licenseData,
            privateKey: privateKey
        )
        
        let signatureBase64 = signatureData.base64EncodedString()
        
        return LicenseFile(
            signature: signatureBase64,
            license: portableLicense
        )
    }
    
    static func verifyLicenseFile(_ file: LicenseFile) throws -> Bool {
        guard let signatureBase64 = file.signature,
              let signatureData = Data(base64Encoded: signatureBase64)
        else {
            return false
        }
        
        let licenseData = try LicenseSigningService.canonicalLicenseData(file.license)
        
        let privateKey = try SigningIdentityStore.loadOrCreatePrivateKey()
        let publicKey = privateKey.publicKey
        
        return LicenseSigningService.verify(
            signature: signatureData,
            data: licenseData,
            publicKey: publicKey
        )
    }
    
    
    static func runSigningSelfTest() {
        do {
            let privateKey = try SigningIdentityStore.loadOrCreatePrivateKey()
            let publicKey = privateKey.publicKey
            
            let testData = Data("UpDock License Signing Test".utf8)
            
            let signature = try LicenseSigningService.sign(
                data: testData,
                privateKey: privateKey
            )
            
            let isValid = LicenseSigningService.verify(
                signature: signature,
                data: testData,
                publicKey: publicKey
            )
            
            print("UpDock License Signing Self Test")
            print("Signature Valid = \(isValid)")
            print("Persistent Public Key Base64 = \(publicKey.rawRepresentation.base64EncodedString())")
        } catch {
            print("Signing self test failed: \(error.localizedDescription)")
        }
    }
}
