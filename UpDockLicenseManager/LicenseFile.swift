//
//  LicenseFile.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//
import Foundation

struct LicenseFile: Codable {
    var fileType: String
    var formatVersion: Int
    var createdBy: String
    var createdAt: Date
    
    var signingIdentity: String
    var signatureAlgorithm: String
    var signature: String?
    
    var license: UpDockLicense
    
    init(
        fileType: String = "UpDockLicense",
        formatVersion: Int = 1,
        createdBy: String = "UpDock License Manager",
        createdAt: Date = Date(),
        signingIdentity: String = "Stockly Consulting",
        signatureAlgorithm: String = "Ed25519",
        signature: String? = nil,
        license: UpDockLicense
    ) {
        self.fileType = fileType
        self.formatVersion = formatVersion
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.signingIdentity = signingIdentity
        self.signatureAlgorithm = signatureAlgorithm
        self.signature = signature
        self.license = license
    }
}
