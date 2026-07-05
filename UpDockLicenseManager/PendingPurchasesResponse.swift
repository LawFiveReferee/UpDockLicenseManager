//
//  PendingPurchasesResponse.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

struct PendingPurchasesResponse: Codable {
  let status: String
  let apiVersion: Int?
  let count: Int
  let items: [PendingPaddlePurchase]
}

struct PendingPaddlePurchase: Codable, Identifiable, Hashable {
  let receivedAt: String
  let eventType: String
  let transactionID: String
  let payload: PaddleWebhookPayload

  var id: String { transactionID }

  enum CodingKeys: String, CodingKey {
    case receivedAt = "received_at"
    case eventType = "event_type"
    case transactionID = "transaction_id"
    case payload
  }
}

struct PaddleWebhookPayload: Codable, Hashable {
  let eventType: String?
  let data: PaddleTransactionData?

  enum CodingKeys: String, CodingKey {
    case eventType = "event_type"
    case data
  }
}

struct PaddleTransactionData: Codable, Hashable {
  let id: String?
  let status: String?
  let customerID: String?
  let customer: PaddleCustomerData?
  let items: [PaddleTransactionItem]?
  let details: PaddleTransactionDetails?

  enum CodingKeys: String, CodingKey {
    case id
    case status
    case customerID = "customer_id"
    case customer
    case items
    case details
  }

  var primaryItem: PaddleTransactionItem? {
    guard var item = items?.first else {
      return nil
    }

    if item.product == nil {
      item.product = details?.lineItems?.first { lineItem in
        lineItem.priceID == item.price?.id
      }?.product
    }

    return item
  }
}

struct PaddleCustomerData: Codable, Hashable {
  let id: String?
  let email: String?
  let name: String?
}

struct PaddleTransactionItem: Codable, Hashable {
  let price: PaddlePriceData?
  var product: PaddleProductData?
}

struct PaddlePriceData: Codable, Hashable {
  let id: String?
  let productID: String?

  enum CodingKeys: String, CodingKey {
    case id
    case productID = "product_id"
  }
}

struct PaddleProductData: Codable, Hashable {
  let id: String?
  let name: String?
}

struct PaddleTransactionDetails: Codable, Hashable {
  let lineItems: [PaddleLineItem]?

  enum CodingKeys: String, CodingKey {
    case lineItems = "line_items"
  }
}

struct PaddleLineItem: Codable, Hashable {
  let priceID: String?
  let product: PaddleProductData?

  enum CodingKeys: String, CodingKey {
    case priceID = "price_id"
    case product
  }
}

struct FulfilledPurchaseResponse: Decodable, Hashable {
  var status: String?
  var transactionID: String?
  var alreadyFulfilled: Bool
  var message: String?

  enum CodingKeys: String, CodingKey {
    case status
    case transactionID = "transaction_id"
    case alreadyFulfilled
    case alreadyFulfilledSnake = "already_fulfilled"
    case message
  }

  init(
    status: String? = nil,
    transactionID: String? = nil,
    alreadyFulfilled: Bool = false,
    message: String? = nil
  ) {
    self.status = status
    self.transactionID = transactionID
    self.alreadyFulfilled = alreadyFulfilled
    self.message = message
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let camelCaseAlreadyFulfilled = try container.decodeIfPresent(
      Bool.self,
      forKey: .alreadyFulfilled
    )
    let snakeCaseAlreadyFulfilled = try container.decodeIfPresent(
      Bool.self,
      forKey: .alreadyFulfilledSnake
    )

    status = try container.decodeIfPresent(String.self, forKey: .status)
    transactionID = try container.decodeIfPresent(String.self, forKey: .transactionID)
    alreadyFulfilled = camelCaseAlreadyFulfilled ?? snakeCaseAlreadyFulfilled ?? false
    message = try container.decodeIfPresent(String.self, forKey: .message)
  }
}
