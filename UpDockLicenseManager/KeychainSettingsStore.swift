//
//  KeychainSettingsStore.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//
import Foundation
import Security

final class KeychainSettingsStore {
    
    static let shared = KeychainSettingsStore()
    
    enum Key: String, CaseIterable {
        case paddleAPIKey
        case paddleNotificationSecret
        case managerToken
    }
    
    private let service = "com.stockly.UpDockLicenseManager"
    
    private init() { }
    
    var paddleAPIKey: String {
        get { value(for: .paddleAPIKey) }
        set { set(newValue, for: .paddleAPIKey) }
    }
    
    var paddleNotificationSecret: String {
        get { value(for: .paddleNotificationSecret) }
        set { set(newValue, for: .paddleNotificationSecret) }
    }
    
    var managerToken: String {
        get { value(for: .managerToken) }
        set { set(newValue, for: .managerToken) }
    }
    
    func value(for key: Key) -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard
            status == errSecSuccess,
            let data = result as? Data,
            let string = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        
        return string
    }
    
    func set(_ value: String, for key: Key) {
        let data = Data(value.utf8)
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let add: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue,
            kSecValueData: data
        ]
        
        SecItemAdd(add as CFDictionary, nil)
    }
    
    func remove(_ key: Key) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key.rawValue
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
