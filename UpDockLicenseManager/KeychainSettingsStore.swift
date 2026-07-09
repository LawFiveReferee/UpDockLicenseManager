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
    set { _ = save(newValue, for: .paddleAPIKey) }
  }

  var paddleNotificationSecret: String {
    get { value(for: .paddleNotificationSecret) }
    set { _ = save(newValue, for: .paddleNotificationSecret) }
  }

  var managerToken: String {
    get { value(for: .managerToken) }
    set { _ = save(newValue, for: .managerToken) }
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

    if key == .paddleAPIKey && isRetiredPaddleAPIPlaceholder(string) {
      remove(key)
      return ""
    }

    return string
  }

  @discardableResult
  func save(_ value: String, for key: Key) -> KeychainSaveResult {
    if key == .paddleAPIKey && isRetiredPaddleAPIPlaceholder(value) {
      remove(key)
      return .removedRetiredPlaceholder
    }

    let data = Data(value.utf8)

    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key.rawValue
    ]

    let update: [CFString: Any] = [
      kSecValueData: data
    ]

    let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)

    if updateStatus == errSecSuccess {
      return .saved
    }

    guard updateStatus == errSecItemNotFound else {
      return .failed(updateStatus)
    }

    let add: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key.rawValue,
      kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      kSecValueData: data
    ]

    let addStatus = SecItemAdd(add as CFDictionary, nil)

    if addStatus == errSecSuccess {
      return .saved
    }

    return .failed(addStatus)
  }

  func remove(_ key: Key) {
    let query: [CFString: Any] = [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key.rawValue
    ]

    SecItemDelete(query as CFDictionary)
  }

  private func isRetiredPaddleAPIPlaceholder(_ value: String) -> Bool {
    value.trimmingCharacters(in: .whitespacesAndNewlines) == "test_api_key_123"
  }
}

enum KeychainSaveResult: Equatable {
  case saved
  case removedRetiredPlaceholder
  case failed(OSStatus)

  var didSave: Bool {
    self == .saved
  }

  var message: String {
    switch self {
    case .saved:
      return "Saved to Keychain."
    case .removedRetiredPlaceholder:
      return "Removed retired placeholder from Keychain."
    case .failed(let status):
      return "Keychain save failed with OSStatus \(status)."
    }
  }
}
