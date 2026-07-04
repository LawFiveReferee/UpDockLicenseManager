//
//  PendingPurchasesView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/3/26.
//
// 
import SwiftUI
import AppKit

struct PendingPurchasesView: View {
    @Environment(\.dismiss) private var dismiss
    
    let onFulfillPurchase: (LicenseRecord) -> Void
    
    @State private var networkSettings = NetworkSettings()
    @State private var purchases: [PendingPaddlePurchase] = []
    @State private var selectedPurchaseID: PendingPaddlePurchase.ID?
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var selectedPurchase: PendingPaddlePurchase? {
        purchases.first { $0.id == selectedPurchaseID }
    }
    
    var body: some View {
        NavigationSplitView {
            purchaseList
        } detail: {
            purchaseDetail
        }
        .frame(width: 1000, height: 680)
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Section("Generate") {
                        Button("Generate 1") {
                            Task { await generateTestPurchases(count: 1) }
                        }
                        
                        Button("Generate 5") {
                            Task { await generateTestPurchases(count: 5) }
                        }
                        
                        Button("Generate 10") {
                            Task { await generateTestPurchases(count: 10) }
                        }
                        
                        Button("Generate 100") {
                            Task { await generateTestPurchases(count: 100) }
                        }
                    }
                    
                    Divider()
                    
                    Section("Clear Test Purchases") {
                        Button("Clear Pending Tests") {
                            Task { await clearPendingTests() }
                        }
                        
                        Button("Clear Fulfilled Tests") {
                            Task { await clearFulfilledTests() }
                        }
                        
                        Button("Clear All Tests") {
                            Task { await clearAllTests() }
                        }
                    }
                } label: {
                    Label("Developer", systemImage: "hammer")
                }
                .disabled(isLoading)
                
                Button {
                    Task { await refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
                
                Button("Close") {
                    dismiss()
                }
            }
        }
        .task {
            await refresh()
        }
    }
    
    private var purchaseList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pending Purchases")
                .font(.title2.bold())
                .padding(.horizontal)
                .padding(.top)
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            
            if isLoading {
                ProgressView("Loading…")
                    .padding(.horizontal)
            }
            
            List(selection: $selectedPurchaseID) {
                ForEach(purchases) { purchase in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(purchase.payload.data?.customer?.email ?? "Unknown Customer")
                            .font(.headline)
                        
                        Text(purchase.payload.data?.customer?.name ?? "—")
                            .foregroundStyle(.secondary)
                        
                        Text(purchase.transactionID)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .tag(purchase.id)
                }
            }
            .overlay {
                if purchases.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No Pending Purchases",
                        systemImage: "tray",
                        description: Text("Generate test purchases or wait for Paddle webhooks.")
                    )
                }
            }
        }
        .frame(minWidth: 340)
    }
    
    private var purchaseDetail: some View {
        Group {
            if let selectedPurchase {
                PendingPurchaseDetailView(
                    purchase: selectedPurchase,
                    networkSettings: networkSettings,
                    onFulfillPurchase: { purchase in
                        let license = FulfillmentCoordinator.shared
                            .makeCommercialLicenseRecord(from: purchase)
                        
                        Task {
                            await fulfillPurchase(
                                purchase: purchase,
                                license: license
                            )
                        }
                    }
                )
            } else {
                ContentUnavailableView(
                    "No Purchase Selected",
                    systemImage: "creditcard",
                    description: Text("Select a pending purchase to review it.")
                )
            }
        }
    }
    
    private func refresh() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await PendingPurchasesService.shared
                .fetchPendingPurchases(settings: networkSettings)
            
            purchases = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func generateTestPurchases(count: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await ServerService.shared.generateTestPurchases(
                settings: networkSettings,
                count: count
            )
            
            let response = try await PendingPurchasesService.shared
                .fetchPendingPurchases(settings: networkSettings)
            
            purchases = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func clearPendingTests() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await ServerService.shared.clearPendingTestPurchases(
                settings: networkSettings
            )
            
            let response = try await PendingPurchasesService.shared
                .fetchPendingPurchases(settings: networkSettings)
            
            purchases = response.items
            selectedPurchaseID = purchases.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func clearFulfilledTests() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await ServerService.shared.clearFulfilledTestPurchases(
                settings: networkSettings
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func clearAllTests() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await ServerService.shared.clearAllTestPurchases(
                settings: networkSettings
            )
            
            let response = try await PendingPurchasesService.shared
                .fetchPendingPurchases(settings: networkSettings)
            
            purchases = response.items
            selectedPurchaseID = purchases.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fulfillPurchase(
        purchase: PendingPaddlePurchase,
        license: LicenseRecord
    ) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await PendingPurchasesService.shared.markFulfilled(
                settings: networkSettings,
                transactionID: purchase.transactionID
            )
            
            onFulfillPurchase(license)
            
            purchases.removeAll {
                $0.transactionID == purchase.transactionID
            }
            
            selectedPurchaseID = purchases.first?.id
            
            let response = try await PendingPurchasesService.shared
                .fetchPendingPurchases(settings: networkSettings)
            
            purchases = response.items
            selectedPurchaseID = purchases.first?.id
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }}

struct PendingPurchaseDetailView: View {
    let purchase: PendingPaddlePurchase
    let networkSettings: NetworkSettings
    let onFulfillPurchase: (PendingPaddlePurchase) -> Void
    
    private var transaction: PaddleTransactionData? {
        purchase.payload.data
    }
    
    private var customer: PaddleCustomerData? {
        transaction?.customer
    }
    
    private var item: PaddleTransactionItem? {
        transaction?.items?.first
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Purchase Review")
                    .font(.largeTitle.bold())
                
                detailCard("Customer") {
                    row("Name", customer?.name ?? "—")
                    row("Email", customer?.email ?? "—")
                    row("Customer ID", transaction?.customerID ?? customer?.id ?? "—")
                }
                
                detailCard("Purchase") {
                    row("Transaction ID", purchase.transactionID)
                    row("Status", transaction?.status ?? "—")
                    row("Received", purchase.receivedAt)
                    row("Event Type", purchase.eventType)
                }
                
                detailCard("Server Test Links") {
                    let fulfilledURL = networkSettings.authenticatedFulfilledURL(
                        transactionID: purchase.transactionID
                    )
                    
                    row("Mark Fulfilled URL", fulfilledURL)
                    
                    HStack {
                        Button("Copy Mark Fulfilled URL") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(fulfilledURL, forType: .string)
                        }
                        
                        Button("Open Mark Fulfilled URL") {
                            if let url = URL(string: fulfilledURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                }
                
                detailCard("Product") {
                    row("Product", item?.product?.name ?? "—")
                    row("Product ID", item?.product?.id ?? "—")
                    row("Price ID", item?.price?.id ?? "—")
                }
                
                detailCard("License Preview") {
                    row("License Type", "Commercial")
                    row("Expiration", "None")
                    row("Will Generate", "Signed .updocklicense")
                }
                
                HStack {
                    Button("Preview License") {
                        // Later
                    }
                    .disabled(true)
                    
                    Button("Fulfill Purchase") {
                        onFulfillPurchase(purchase)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
        }
    }
    
    private func detailCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)
            
            Text(value.isEmpty ? "—" : value)
                .textSelection(.enabled)
        }
    }
}
