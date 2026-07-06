import SwiftUI

struct PaddleSettingsView: View {
  @State private var settings = PaddleSettings()
  @State private var fulfillmentPolicy = PaddleFulfillmentPolicyStore()
  @State private var siteLicensePricing = SiteLicensePricingStore()

  @State private var apiKey = ""
  @State private var notificationSecret = ""
  @State private var showingNotificationSecret = false
  @State private var showingAPIKey = false
  @State private var savedMessage = ""

  var body: some View {
    Form {
      Section("Environment") {
        Picker("Paddle Environment", selection: $settings.environment) {
          ForEach(PaddleSettings.Environment.allCases) { environment in
            Text(environment.rawValue).tag(environment)
          }
        }
        .pickerStyle(.segmented)
      }

      Section("Secrets") {
        if showingAPIKey {
          TextField("API Key", text: $apiKey)
            .textFieldStyle(.roundedBorder)
        } else {
          SecureField("API Key", text: $apiKey)
            .textFieldStyle(.roundedBorder)
        }

        HStack {
          Button(showingAPIKey ? "Hide" : "Show") {
            showingAPIKey.toggle()
          }

          Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(apiKey, forType: .string)
          }
          .disabled(apiKey.isEmpty)

          Button("Save API Key") {
            KeychainSettingsStore.shared.paddleAPIKey = apiKey
            savedMessage = "API key saved to Keychain."
          }
          .buttonStyle(.borderedProminent)
        }

        if !savedMessage.isEmpty {
          Text(savedMessage)
            .foregroundStyle(.secondary)
        }

        Text("The Paddle API key is stored securely in macOS Keychain.")
          .foregroundStyle(.secondary)
      }

      Section("Default Product") {
        TextField("Product ID", text: $settings.defaultProductID)
          .textFieldStyle(.roundedBorder)

        TextField("Price ID", text: $settings.defaultPriceID)
          .textFieldStyle(.roundedBorder)
      }

      Section("Fulfillment Policy") {
        TextField(
          "Site License Price IDs",
          text: $fulfillmentPolicy.siteLicensePriceIDs,
          axis: .vertical
        )
        .lineLimit(2...4)
        .textFieldStyle(.roundedBorder)

        TextField(
          "Site License Product IDs",
          text: $fulfillmentPolicy.siteLicenseProductIDs,
          axis: .vertical
        )
        .lineLimit(2...4)
        .textFieldStyle(.roundedBorder)

        Text("Separate IDs with commas, spaces, or new lines. Matching purchases create one site-license record with the purchased quantity as the seat allowance.")
          .foregroundStyle(.secondary)
      }

      Section("Site License Pricing") {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
          GridRow {
            Text("Min")
            Text("Max")
            Text("Discount")
            Text("Discount Amount")
            Text("New Price")
          }
          .font(.caption)
          .foregroundStyle(.secondary)

          ForEach(siteLicensePricing.tiers.indices, id: \.self) { index in
            GridRow {
              TextField(
                "Min",
                value: $siteLicensePricing.tiers[index].minimumSeats,
                format: .number
              )
              .frame(width: 56)

              TextField(
                "+",
                text: maximumSeatsBinding(for: index)
              )
              .frame(width: 56)

              HStack(spacing: 4) {
                TextField(
                  "Discount",
                  value: $siteLicensePricing.tiers[index].discountPercent,
                  format: .number.precision(.fractionLength(0...2))
                )
                .frame(width: 72)

                Text("%")
                  .foregroundStyle(.secondary)
              }

              HStack(spacing: 4) {
                Text("$")
                  .foregroundStyle(.secondary)

                TextField(
                  "Amount",
                  value: $siteLicensePricing.tiers[index].discountAmount,
                  format: .number.precision(.fractionLength(2))
                )
                .frame(width: 82)
              }

              HStack(spacing: 4) {
                Text("$")
                  .foregroundStyle(.secondary)

                TextField(
                  "Price",
                  value: $siteLicensePricing.tiers[index].unitPrice,
                  format: .number.precision(.fractionLength(2))
                )
                .frame(width: 82)
              }
            }
            .textFieldStyle(.roundedBorder)
          }
        }
        .monospacedDigit()

        HStack {
          Button("Restore Defaults") {
            siteLicensePricing.resetToDefaults()
          }

          Text("Use a blank Max value for the open-ended final tier.")
            .foregroundStyle(.secondary)
        }
      }

      Section("Notification Secret") {
        if showingNotificationSecret {
          TextField(
            "Notification Secret",
            text: $notificationSecret
          )
          .textFieldStyle(.roundedBorder)
        } else {
          SecureField(
            "Notification Secret",
            text: $notificationSecret
          )
          .textFieldStyle(.roundedBorder)
        }

        HStack {
          Button(showingNotificationSecret ? "Hide" : "Show") {
            showingNotificationSecret.toggle()
          }

          Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(
              notificationSecret,
              forType: .string
            )
          }
          .disabled(notificationSecret.isEmpty)

          Button("Save Secret") {
            KeychainSettingsStore.shared
              .paddleNotificationSecret = notificationSecret

            savedMessage = "Notification secret saved to Keychain."
          }
          .buttonStyle(.borderedProminent)
        }

        Text("Used to verify Paddle webhook signatures.")
          .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .padding()
    .onAppear {
      apiKey = KeychainSettingsStore.shared.paddleAPIKey
      notificationSecret = KeychainSettingsStore.shared.paddleNotificationSecret
    }
  }

  private func maximumSeatsBinding(for index: Int) -> Binding<String> {
    Binding(
      get: {
        guard siteLicensePricing.tiers.indices.contains(index) else {
          return ""
        }

        return siteLicensePricing.tiers[index].maximumSeats.map(String.init) ?? ""
      },
      set: { newValue in
        guard siteLicensePricing.tiers.indices.contains(index) else {
          return
        }

        let trimmedValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedValue.isEmpty {
          siteLicensePricing.tiers[index].maximumSeats = nil
        } else if let maximumSeats = Int(trimmedValue) {
          siteLicensePricing.tiers[index].maximumSeats = maximumSeats
        }
      }
    )
  }
}
