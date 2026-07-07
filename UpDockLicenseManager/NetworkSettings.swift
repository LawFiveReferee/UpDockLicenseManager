//
//  NetworkSettings.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//

import Foundation
import Observation

@Observable
final class NetworkSettings {

    var serverBaseURL: String {
        didSet { save() }
    }

    private let defaults = UserDefaults.standard

    init() {
        serverBaseURL =
        defaults.string(forKey: "network.serverBaseURL")
        ?? "https://updockapp.com/paddle"
    }

    private func save() {
        defaults.set(
            serverBaseURL,
            forKey: "network.serverBaseURL"
        )
    }

    var healthURL: String {
        serverBaseURL + "/health.php"
    }

    var pendingURL: String {
        serverBaseURL + "/pending.php"
    }

    var authenticatedPendingURL: String {
        let token = KeychainSettingsStore.shared.managerToken

        guard !token.isEmpty else {
            return pendingURL + "?token="
        }

        return pendingURL + "?token=" + token
    }

    var authenticatedFulfilledURL: String {
        let token = KeychainSettingsStore.shared.managerToken

        guard !token.isEmpty else {
            return fulfilledURL + "?token="
        }

        return fulfilledURL + "?token=" + token
    }

    var fulfilledURL: String {
        serverBaseURL + "/fulfilled.php"
    }

    var webhookURL: String {
        serverBaseURL + "/webhook.php"
    }

    var licenseRegisterURL: String {
        serverBaseURL + "/license-register.php"
    }

    var activationURL: String {
        serverBaseURL + "/activate.php"
    }

    var deactivationURL: String {
        serverBaseURL + "/deactivate.php"
    }

    var activationStatusURL: String {
        serverBaseURL + "/activation-status.php"
    }

    var operationsStatusURL: String {
        serverBaseURL + "/operations-status.php"
    }

    var authenticatedOperationsStatusURL: String {
        authenticatedURL(
            baseURL: operationsStatusURL,
            queryItems: []
        )
    }

    var simulateURL: String {
        serverBaseURL + "/simulate.php"
    }

    func authenticatedFulfilledURL(transactionID: String) -> String {
        let token = KeychainSettingsStore.shared.managerToken

        var components = URLComponents(string: fulfilledURL)
        components?.queryItems = [
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "transaction_id", value: transactionID)
        ]

        return components?.url?.absoluteString ?? ""
    }

    func authenticatedPendingURLString() -> String {
        authenticatedPendingURL
    }

    func authenticatedSimulateURL(count: Int) -> String {
        let token = KeychainSettingsStore.shared.managerToken
        return simulateURL + "?token=" + token + "&count=\(count)"
    }

    func activationRegisterURL(
        serial: String,
        seatAllowance: Int
    ) -> String {
        authenticatedURL(
            baseURL: licenseRegisterURL,
            queryItems: [
                URLQueryItem(name: "serial", value: serial),
                URLQueryItem(name: "seat_allowance", value: "\(seatAllowance)")
            ]
        )
    }

    func activationURL(
        serial: String,
        machineID: String,
        machineName: String
    ) -> String {
        unauthenticatedURL(
            baseURL: activationURL,
            queryItems: [
                URLQueryItem(name: "serial", value: serial),
                URLQueryItem(name: "machine_id", value: machineID),
                URLQueryItem(name: "machine_name", value: machineName)
            ]
        )
    }

    func deactivationURL(
        serial: String,
        machineID: String
    ) -> String {
        unauthenticatedURL(
            baseURL: deactivationURL,
            queryItems: [
                URLQueryItem(name: "serial", value: serial),
                URLQueryItem(name: "machine_id", value: machineID)
            ]
        )
    }

    func activationStatusURL(serial: String) -> String {
        authenticatedURL(
            baseURL: activationStatusURL,
            queryItems: [
                URLQueryItem(name: "serial", value: serial)
            ]
        )
    }

    private func authenticatedURL(
        baseURL: String,
        queryItems: [URLQueryItem]
    ) -> String {
        let token = KeychainSettingsStore.shared.managerToken
        var components = URLComponents(string: baseURL)
        components?.queryItems = [URLQueryItem(name: "token", value: token)] + queryItems

        return components?.url?.absoluteString ?? ""
    }

    private func unauthenticatedURL(
        baseURL: String,
        queryItems: [URLQueryItem]
    ) -> String {
        var components = URLComponents(string: baseURL)
        components?.queryItems = queryItems

        return components?.url?.absoluteString ?? ""
    }
}
