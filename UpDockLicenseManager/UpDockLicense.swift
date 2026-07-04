//
//  UpDockLicense.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation

struct UpDockLicense: Codable, Hashable {
    var formatVersion: Int
    var serial: String
    var type: UpDockLicenseType
    var product: String
    var name: String
    var email: String
    var issuedAt: Date
    var expiresAt: Date?
    var signature: String?
    
    init(
        formatVersion: Int = 1,
        serial: String,
        type: UpDockLicenseType,
        product: String = "UpDock Pro",
        name: String,
        email: String,
        issuedAt: Date,
        expiresAt: Date?,
        signature: String? = nil
    ) {
        self.formatVersion = formatVersion
        self.serial = serial
        self.type = type
        self.product = product
        self.name = name
        self.email = email
        self.issuedAt = issuedAt
        self.expiresAt = expiresAt
        self.signature = signature
    }
}

extension UpDockLicense {
    init(record: LicenseRecord) {
        self.init(
            serial: record.serial,
            type: record.type,
            product: record.product,
            name: record.name,
            email: record.email,
            issuedAt: record.issuedAt,
            expiresAt: record.expiresAt,
            signature: nil
        )
    }
}
