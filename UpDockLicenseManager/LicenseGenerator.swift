//
//  LicenseGenerator.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//
import Foundation

enum LicenseGenerator {
    private static let alphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    
    static func makeSerial(
        type: UpDockLicenseType,
        year: Int = Calendar.current.component(.year, from: Date())
    ) -> String {
        switch type {
        case .beta:
            return "UPD-PRO-BETA-\(year)-\(block())-\(block())-\(block())"
        case .trial:
            return "UPD-PRO-TRIAL-\(year)-\(block())-\(block())-\(block())"
        case .commercial:
            return "UPD-PRO-\(year)-\(block())-\(block())-\(block())"
        }
    }
    
    private static func block(length: Int = 4) -> String {
        String((0..<length).compactMap { _ in alphabet.randomElement() })
    }
}
