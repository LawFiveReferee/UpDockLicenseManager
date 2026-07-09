//
//  ToolbarContent.swift
//  UpDock License Manager
//
//  Created by Ed Stockly on 7/1/26.
//

import SwiftUI

struct LicenseToolbarContent: ToolbarContent {
  let selectedLicense: LicenseRecord?
  let showsTextLabels: Bool
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
  let onShowAuditLog: () -> Void
  let onShowRecoveryReport: () -> Void
  let onRemoveAllDevelopmentLicenses: () -> Void

  var body: some ToolbarContent {
    ToolbarItemGroup {
      SettingsLink {
        toolbarLabel("Settings", systemImage: "gearshape")
      }
      .help("Settings")

      Button {
        LicenseService.runSigningSelfTest()
      } label: {
        toolbarLabel("Signing Test", systemImage: "checkmark.seal")
      }
      .help("Signing Test")
    }

    ToolbarItemGroup {
      Button {
        onNew()
      } label: {
        toolbarLabel("New License", systemImage: "plus")
      }
      .help("New License")
      .keyboardShortcut("n", modifiers: .command)

      Button {
        onFulfillPaddlePurchase()
      } label: {
        toolbarLabel("Fulfill Paddle", systemImage: "creditcard")
      }
      .help("Fulfill Paddle")

      Button {
        onShowPendingPurchases()
      } label: {
        toolbarLabel("Pending Purchases", systemImage: "tray.full")
      }
      .help("Pending Purchases")

      Button {
        onShowAuditLog()
      } label: {
        toolbarLabel("Audit Log", systemImage: "clock.badge")
      }
      .help("Audit Log")

      Button {
        onShowRecoveryReport()
      } label: {
        toolbarLabel("Recovery Report", systemImage: "wrench.and.screwdriver")
      }
      .help("Recovery Report")

      Button {
        onDuplicate()
      } label: {
        toolbarLabel("Duplicate", systemImage: "plus.square.on.square")
      }
      .disabled(selectedLicense == nil)
      .help("Duplicate")
      .keyboardShortcut("d", modifiers: .command)

      Button {
        onDelete()
      } label: {
        toolbarLabel("Delete", systemImage: "trash")
      }

      .disabled(selectedLicense == nil)
      .help("Delete")
      .keyboardShortcut(.delete, modifiers: [])
      Button {
        onUndoDelete()
      } label: {
        toolbarLabel("Undo Delete", systemImage: "arrow.uturn.backward")
      }
      .disabled(!canUndoDelete)
      .help("Undo Delete")
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
        toolbarLabel("Sort", systemImage: "arrow.up.arrow.down")
      }
      .help("Sort")

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
        toolbarLabel("Export", systemImage: "square.and.arrow.up")
      }
      .help("Export")

      Menu {
        Button("Remove All Local Licenses…", role: .destructive) {
          onRemoveAllDevelopmentLicenses()
        }
      } label: {
        toolbarLabel("Development", systemImage: "hammer")
      }
      .help("Development")
    }
  }

  @ViewBuilder
  private func toolbarLabel(_ title: String, systemImage: String) -> some View {
    if showsTextLabels {
      Label(title, systemImage: systemImage)
        .labelStyle(.titleAndIcon)
    } else {
      Label(title, systemImage: systemImage)
        .labelStyle(.iconOnly)
    }
  }
}
