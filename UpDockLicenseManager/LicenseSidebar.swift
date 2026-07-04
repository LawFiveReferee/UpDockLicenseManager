//
//  LicenseSidebar.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseSidebar: View {
    let store: LicenseStore
    @Binding var selectedFilter: LicenseSidebarFilter
    
    var body: some View {
        List(selection: $selectedFilter) {
            Section("Licenses") {
                ForEach(LicenseSidebarFilter.allCases) { filter in
                    SidebarFilterRow(
                        filter: filter,
                        count: store.count(for: filter)
                    )
                    .tag(filter)
                }
            }
        }
        .navigationTitle("Licenses")
    }
}

struct SidebarFilterRow: View {
    let filter: LicenseSidebarFilter
    let count: Int
    
    var body: some View {
        HStack {
            Label(filter.rawValue, systemImage: filter.symbol)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
