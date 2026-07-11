//
//  HealthResponse.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation

struct HealthResponse: Codable {

  let status: String

  let php: String

  let time: String

  let transactionsWritable: Bool

  let fulfilledWritable: Bool

  let licensesWritable: Bool?

  let activationsWritable: Bool?

  let deliveredLicensesWritable: Bool?

  let privateConfigLoaded: Bool?

  let paddleApiMode: String?

  let webhookLogWritable: Bool?

  let autoFulfillment: AutoFulfillmentHealth?
}

struct AutoFulfillmentHealth: Codable {

  let enabled: Bool?

  let signingKeyConfigured: Bool?

  let sodiumAvailable: Bool?

  let mailAvailable: Bool?
}
