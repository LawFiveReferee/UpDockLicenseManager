//
//  SigningIdentityStore.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation
import CryptoKit
import Security

enum SigningIdentityStore {
    private static let service = "com.stockly.updock-license-manager"
    private static let account = "UpDockLicenseSigningPrivateKey"
    
    static func loadOrCreatePrivateKey() throws -> Curve25519.Signing.PrivateKey {
        if let existingKey = try loadPrivateKey() {
            return existingKey
        }
        
        let newKey = Curve25519.Signing.PrivateKey()
        try savePrivateKey(newKey)
        return newKey
    }
    
    static func loadPrivateKey() throws -> Curve25519.Signing.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return try Curve25519.Signing.PrivateKey(rawRepresentation: data)
    }
    
    static func savePrivateKey(_ privateKey: Curve25519.Signing.PrivateKey) throws {
        let data = privateKey.rawRepresentation
        
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(deleteQuery as CFDictionary)
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledStatus(status)
        }
    }
    
    static func publicKeyBase64() throws -> String {
        let privateKey = try loadOrCreatePrivateKey()
        return privateKey.publicKey.rawRepresentation.base64EncodedString()
    }
    
    static func exportPublicKeySwiftFile(to url: URL) throws {
        let publicKey = try publicKeyBase64()
        
        let source = """
    import Foundation
    
    enum UpDockLicensePublicKey {
        static let base64 = "\(publicKey)"
    }
    
    """
        
        try source.write(to: url, atomically: true, encoding: .utf8)
    }
}


enum KeychainError: Error, LocalizedError {
    case unhandledStatus(OSStatus)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .unhandledStatus(let status):
            return "Keychain error: \(status)"
        case .invalidData:
            return "The signing key stored in Keychain is invalid."
        }
    }
}
