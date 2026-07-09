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

    static func makeEmailBody(
        for license: LicenseRecord,
        settings: EmailSettings = EmailSettings()
    ) -> String {
        let name = license.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let greeting = name.isEmpty ? "Hello," : "Hello \(name),"
        let signatureName = settings.signatureName.trimmingCharacters(in: .whitespacesAndNewlines)
        let signatureEmail = settings.signatureEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let signatureURL = settings.signatureURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let purchaseReference = license.paddleTransactionID.trimmingCharacters(in: .whitespacesAndNewlines)
        let purchaseLine = purchaseReference.isEmpty
            ? ""
            : "\nPurchase reference: \(purchaseReference)"
        let customerID = license.paddleCustomerID.trimmingCharacters(in: .whitespacesAndNewlines)
        let customerLine = customerID.isEmpty
            ? ""
            : "\nPaddle customer ID: \(customerID)"
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
        Issued: \(license.issuedAt.formatted(date: .long, time: .omitted))
        \(seatLine)\(purchaseLine)\(customerLine)

        \(expirationLine)

        If you have any questions, reply to this email.

        Thank you,

        \(signatureName.isEmpty ? "UpDock Customer Service" : signatureName)
        \(signatureEmail.isEmpty ? "customerservice@updockapp.com" : signatureEmail)
        \(signatureURL.isEmpty ? "https://updockapp.com/pro.html" : signatureURL)
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
