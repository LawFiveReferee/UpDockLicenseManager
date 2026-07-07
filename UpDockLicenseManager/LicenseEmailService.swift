//
//  LicenseEmailService.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import Foundation
import AppKit

enum LicenseEmailService {
    static func makeEmailSubject(for license: LicenseRecord) -> String {
        if let seatAllowance = license.seatAllowance, seatAllowance > 1 {
            return "Your UpDock Pro Site License"
        }

        return "Your UpDock Pro License"
    }

    static func makeEmailBody(for license: LicenseRecord) -> String {
        let name = license.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = name.isEmpty ? "Hello," : "Hello \(name),"
        let purchaseReference = license.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines)
        let purchaseLine = purchaseReference.isEmpty
            ? ""
            : "\nPurchase reference: \(purchaseReference)"
        let seatLine: String

        let expirationLine: String

        if let expiresAt = license.expiresAt {
            expirationLine = "This \(license.type.rawValue.lowercased()) license expires on \(expiresAt.formatted(date: .long, time: .omitted))."
        } else {
            expirationLine = "This license does not expire."
        }

        if let seatAllowance = license.seatAllowance, seatAllowance > 1 {
            seatLine = "This site license allows activation on up to \(seatAllowance) Macs."
        } else {
            seatLine = "This license allows activation on one Mac."
        }

        return """
        \(greeting)

        Attached is your UpDock Pro license file.

        To install it, open UpDock Pro and import the attached .updocklicense file.

        Serial: \(license.serial)
        \(seatLine)\(purchaseLine)

        \(expirationLine)

        If you have any questions, reply to this email.

        Thank you,

        Stockly Consulting
        """
    }

    static func openMailDraft(
        to recipient: String,
        subject: String,
        body: String,
        attachmentURL: URL
    ) throws {
        guard let service = NSSharingService(named: .composeEmail) else {
            throw LicenseEmailError.mailServiceUnavailable
        }

        let trimmedRecipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedRecipient.isEmpty {
            service.recipients = [trimmedRecipient]
        }

        service.subject = subject

        service.perform(withItems: [
            body,
            attachmentURL
        ])
    }
}

enum LicenseEmailError: Error, LocalizedError {
    case mailServiceUnavailable

    var errorDescription: String? {
        switch self {
        case .mailServiceUnavailable:
            return "The macOS email compose service is not available."
        }
    }
}
