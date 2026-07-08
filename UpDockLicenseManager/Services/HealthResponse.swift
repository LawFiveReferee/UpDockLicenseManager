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

    let privateConfigLoaded: Bool?

    let paddleApiMode: String?

    let webhookLogWritable: Bool?
}
