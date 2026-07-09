//
//  LicenseDashboardView.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseDashboardView: View {
    let store: LicenseStore
    private let dashboardColumns = [
        GridItem(.adaptive(minimum: 120), spacing: 16, alignment: .leading)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("UpDock Pro License Manager")
                    .font(.largeTitle.bold())
                
                LazyVGrid(columns: dashboardColumns, alignment: .leading, spacing: 16) {
                    dashboardCard("All", store.totalCount)
                    dashboardCard("Active", store.activeCount)
                    dashboardCard("Expiring Soon", store.expiringSoonCount)
                    dashboardCard("Expired", store.expiredCount)
                    dashboardCard("Revoked", store.revokedCount)
                    dashboardCard("Active Beta", store.activeBetaCount)
                    dashboardCard("Active Trial", store.activeTrialCount)
                    dashboardCard("Active Commercial", store.activeCommercialCount)
                }

                 if let newest = store.licenses.first {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Newest License")
                            .font(.headline)
                        
                        Text(newest.serial)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                        
                        Text(newest.name.isEmpty ? "Unassigned" : newest.name)
                            .foregroundStyle(.secondary)
                        
                        if !newest.email.isEmpty {
                            Text(newest.email)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func dashboardCard(_ title: String, _ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("\(count)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
