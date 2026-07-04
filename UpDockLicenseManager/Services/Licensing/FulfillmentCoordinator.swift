//
//  FulfillmentCoordinator.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

final class FulfillmentCoordinator {
    static let shared = FulfillmentCoordinator()
    
    private init() {}
    
    func makeCommercialLicenseRecord(
        from purchase: PendingPaddlePurchase
    ) -> LicenseRecord {
        let transaction = purchase.payload.data
        let customer = transaction?.customer
        let item = transaction?.items?.first
        
        let name = customer?.name ?? ""
        let email = customer?.email ?? ""
        
        return LicenseRecord(
            serial: LicenseGenerator.makeSerial(type: .commercial),
            type: .commercial,
            name: name,
            email: email,
            expiresAt: nil,
            notes: "Created from pending Paddle purchase.",
            paddleCustomerID: transaction?.customerID ?? customer?.id ?? "",
            paddleTransactionID: purchase.transactionID,
            paddleEmail: email,
            paddleProductID: item?.product?.id ?? "",
            paddlePriceID: item?.price?.id ?? "",
            paddleStatus: transaction?.status ?? "",
            fulfilledAt: Date()
        )
    }
}
