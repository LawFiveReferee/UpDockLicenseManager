//
//  ToolbarContent.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseToolbarContent: ToolbarContent {
    let selectedLicense: LicenseRecord?
    @Binding var sortOption: LicenseSortOption
    
    let onNew: () -> Void
    let onFulfillPaddlePurchase: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onExportJSON: () -> Void
    let onExportCSV: () -> Void
    let onUndoDelete: () -> Void
    let canUndoDelete: Bool
    let onExportLicenseFile: () -> Void
    let onInspectLicenseFile: () -> Void
    let onExportAndRevealLicenseFile: () -> Void
    let onExportAndEmailLicenseFile: () -> Void
    let onShowPendingPurchases: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                onNew()
            } label: {
                Label("New License", systemImage: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button {
                onFulfillPaddlePurchase()
            } label: {
                Label("Fulfill Paddle", systemImage: "creditcard")
            }
            
            Button {
                onShowPendingPurchases()
            } label: {
                Label("Pending Purchases", systemImage: "tray.full")
            }
            
            Button {
                onDuplicate()
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
            .disabled(selectedLicense == nil)
            .keyboardShortcut("d", modifiers: .command)
            
            Button {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            .disabled(selectedLicense == nil)
            .keyboardShortcut(.delete, modifiers: [])
            Button {
                onUndoDelete()
            } label: {
                Label("Undo Delete", systemImage: "arrow.uturn.backward")
            }
            .disabled(!canUndoDelete)
            .keyboardShortcut("z", modifiers: .command)
            
            Menu {
                ForEach(LicenseSortOption.allCases) { option in
                    Button {
                        sortOption = option
                    } label: {
                        if sortOption == option {
                            Label(option.rawValue, systemImage: "checkmark")
                        } else {
                            Text(option.rawValue)
                        }
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            
            Menu {
                Button("Export JSON") {
                    onExportJSON()
                }
                
                Button("Export CSV") {
                    onExportCSV()
                }
                Divider()
                
                Button("Inspect License File…") {
                    onInspectLicenseFile()
                }

                Button("Export License File…") {
                    onExportLicenseFile()
                }
                .disabled(selectedLicense == nil)
                Button("Export and Reveal in Finder…") {
                    onExportAndRevealLicenseFile()
                }
                .disabled(selectedLicense == nil)
                
                Button("Export and Email…") {
                    onExportAndEmailLicenseFile()
                }
                .disabled(selectedLicense == nil)
                
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            Button {
                LicenseService.runSigningSelfTest()
            } label: {
                Label("Signing Test", systemImage: "checkmark.seal")
            }
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
