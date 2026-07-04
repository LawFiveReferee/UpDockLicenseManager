//
//  TokenGenerator.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation
import Security

enum TokenGenerator {
    static func makeManagerToken(byteCount: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        
        let status = SecRandomCopyBytes(
            kSecRandomDefault,
            byteCount,
            &bytes
        )
        
        guard status == errSecSuccess else {
            return UUID().uuidString + "-" + UUID().uuidString
        }
        
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}
