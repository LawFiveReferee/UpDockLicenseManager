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

        UpDock Pro App Download

        To register your copy open the UpDock Pro app, select Show UpDock Pro Settings… from the UpDock menu, and import the attached license file.

        Serial: \(license.serial)
        Issued: \(license.issuedAt.formatted(date: .long, time: .omitted))
        \(seatLine)\(purchaseLine)\(customerLine)

        \(expirationLine)

        If you have any questions, reply to this email.

        Thank you,

        Email Customer Service at UpDock

        UpDock Pro Webpage
        """
    }

    static func openMailDraft(
        to recipient: String,
        subject: String,
        body: String,
        attachmentURL: URL,
        settings: EmailSettings = EmailSettings()
    ) throws {
        guard let service = NSSharingService(named: .composeEmail) else {
            throw LicenseEmailError.mailServiceUnavailable
        }

        let trimmedRecipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedRecipient.isEmpty {
            service.recipients = [trimmedRecipient]
        }

        service.subject = subject

        let formattedBody = makeLinkedEmailBody(
            body,
            settings: settings
        )

        service.perform(withItems: [
            formattedBody,
            attachmentURL
        ])
    }

    private static func makeLinkedEmailBody(
        _ body: String,
        settings: EmailSettings
    ) -> NSAttributedString {
        let attributedBody = NSMutableAttributedString(string: body)
        let fullRange = NSRange(location: 0, length: attributedBody.length)
        let signatureEmail = settings.signatureEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let signatureURL = settings.signatureURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let customerServiceEmail = signatureEmail.isEmpty ? "customerservice@updockapp.com" : signatureEmail
        let proPageURL = signatureURL.isEmpty ? "https://updockapp.com/pro.html" : signatureURL
        let downloadURL = "https://updockapp.com/downloads.html"

        attributedBody.addAttribute(.font, value: NSFont.systemFont(ofSize: NSFont.systemFontSize), range: fullRange)

        addLink(
            to: "Email Customer Service at UpDock",
            urlString: "mailto:\(customerServiceEmail)",
            in: attributedBody
        )
        addLink(
            to: "UpDock Pro App Download",
            urlString: downloadURL,
            in: attributedBody
        )
        addLink(
            to: "UpDock Pro Webpage",
            urlString: proPageURL,
            in: attributedBody
        )

        return attributedBody
    }

    private static func addLink(
        to text: String,
        urlString: String,
        in attributedBody: NSMutableAttributedString
    ) {
        let range = (attributedBody.string as NSString).range(of: text)

        guard range.location != NSNotFound,
              let url = URL(string: urlString) else {
            return
        }

        attributedBody.addAttribute(.link, value: url, range: range)
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
