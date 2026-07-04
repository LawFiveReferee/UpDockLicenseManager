//
//  LicenseSecurityService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

 import Foundation
import CryptoKit

enum LicenseSigningService {
    
    static func generateKeyPair() -> Curve25519.Signing.PrivateKey {
        Curve25519.Signing.PrivateKey()
    }
    
    static func publicKey(from privateKey: Curve25519.Signing.PrivateKey)
    -> Curve25519.Signing.PublicKey
    {
        privateKey.publicKey
    }
    
    static func sign(
        data: Data,
        privateKey: Curve25519.Signing.PrivateKey
    ) throws -> Data {
        
        try privateKey.signature(for: data)
    }
    
    static func verify(
        signature: Data,
        data: Data,
        publicKey: Curve25519.Signing.PublicKey
    ) -> Bool {
        
        publicKey.isValidSignature(signature, for: data)
    }
    static func canonicalLicenseData(_ license: UpDockLicense) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(license)
    }
}
