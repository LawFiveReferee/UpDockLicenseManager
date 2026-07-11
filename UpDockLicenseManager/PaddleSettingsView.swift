import AppKit
import SwiftUI
import UniformTypeIdentifiers

private let paddlePrivateConfigBookmarkKey = "localPrivateConfigBookmark"

struct PaddleSettingsView: View {
  @AppStorage("showDevelopmentTools") private var showDevelopmentTools = false
  @AppStorage("paddle.generatedDiscountCodes") private var generatedDiscountCodes = ""
  @State private var settings = PaddleSettings()
  @State private var fulfillmentPolicy = PaddleFulfillmentPolicyStore()
  @State private var siteLicensePricing = SiteLicensePricingStore()

  @State private var apiKey = ""
  @State private var notificationSecret = ""
  @State private var showingNotificationSecret = false
  @State private var showingAPIKey = false
  @State private var savedMessage = ""
  @State private var discountCodeCount = 10
  @State private var isGeneratingDiscountCodes = false
  @State private var discountCodeMessage = ""

  var body: some View {
    Form {
      Section("Environment") {
        Picker("Paddle Environment", selection: $settings.environment) {
          ForEach(PaddleSettings.Environment.allCases) { environment in
            Text(environment.rawValue).tag(environment)
          }
        }
        .pickerStyle(.segmented)

        LabeledContent("API Base URL") {
          Text(paddleAPIBaseURL)
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
        }

        Button("Update Local Config…") {
          updateLocalPrivateConfig(
            constants: ["PADDLE_API_BASE_URL": paddleAPIBaseURL]
          )
        }
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
            savePaddleAPIKey()
          }
          .buttonStyle(.borderedProminent)

          Button("Update Local Config…") {
            savePaddleAPIKey()
            updateLocalPrivateConfig(
              constants: ["PADDLE_API_KEY": apiKey]
            )
          }
          .disabled(apiKey.isEmpty)
        }

        if !savedMessage.isEmpty {
          Text(savedMessage)
            .foregroundStyle(.secondary)
        }

        Text("The Paddle API key is stored securely in macOS Keychain.")
          .foregroundStyle(.secondary)
      }

      Section("Default Product") {
        TextField("Client-Side Token", text: $settings.clientSideToken)
          .textFieldStyle(.roundedBorder)

        TextField("Product ID", text: $settings.defaultProductID)
          .textFieldStyle(.roundedBorder)

        TextField("Price ID", text: $settings.defaultPriceID)
          .textFieldStyle(.roundedBorder)

        HStack {
          Button("Copy Checkout HTML") {
            copyCheckoutHTMLBlock()
          }
          .disabled(settings.clientSideToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

          Text("Copies the pro.html purchase button block using the current environment, client token, and site-license pricing table.")
            .foregroundStyle(.secondary)
        }
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
        ScrollView(.horizontal) {
          Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
              Text("Min")
              Text("Max")
              Text("Price ID")
              Text("Product ID")
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

                TextField("Price ID", text: $siteLicensePricing.tiers[index].priceID)
                  .frame(width: 190)

                TextField("Product ID", text: $siteLicensePricing.tiers[index].productID)
                  .frame(width: 190)

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
        }

        HStack {
          Button("Restore Defaults") {
            siteLicensePricing.resetToDefaults()
          }

          Text("Use a blank Max value for the open-ended final tier.")
            .foregroundStyle(.secondary)
        }

        Text("Product ID may stay blank when all site-license tiers use the same product. A matching tier Price ID is enough to fulfill as a site license.")
          .foregroundStyle(.secondary)
      }

      if showDevelopmentTools {
        Section("Test Discount Codes") {
          Stepper(
            "Codes to Generate: \(discountCodeCount)",
            value: $discountCodeCount,
            in: 1...20
          )

          LabeledContent("Discount") {
            Text("100% off, one use each")
          }

          LabeledContent("Restricted To") {
            Text(discountPriceIDs.isEmpty ? "No price IDs configured" : "\(discountPriceIDs.count) UpDock Pro price IDs")
          }

          HStack {
            Button {
              Task {
                await generateDiscountCodes()
              }
            } label: {
              if isGeneratingDiscountCodes {
                ProgressView()
              } else {
                Label("Generate Codes", systemImage: "tag")
              }
            }
            .disabled(isGeneratingDiscountCodes || apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || discountPriceIDs.isEmpty)

            Button("Copy Stored Codes") {
              copyGeneratedDiscountCodes()
            }
            .disabled(generatedDiscountCodes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Button("Clear Stored Codes") {
              generatedDiscountCodes = ""
              discountCodeMessage = "Stored discount codes cleared from this app."
            }
            .disabled(generatedDiscountCodes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
          }

          Text("Requires a Paddle API key with discount.write permission. Codes are created in the selected Paddle environment.")
            .foregroundStyle(.secondary)

          if !discountCodeMessage.isEmpty {
            Text(discountCodeMessage)
              .foregroundStyle(.secondary)
              .textSelection(.enabled)
          }

          if !generatedDiscountCodes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(generatedDiscountCodes)
              .font(.caption.monospaced())
              .textSelection(.enabled)
          }
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
            saveNotificationSecret()
          }
          .buttonStyle(.borderedProminent)

          Button("Update Local Config…") {
            saveNotificationSecret()
            updateLocalPrivateConfig(
              constants: ["PADDLE_WEBHOOK_SECRET": notificationSecret]
            )
          }
          .disabled(notificationSecret.isEmpty)
        }

        Text("Used to verify Paddle webhook signatures.")
          .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
    .padding()
    .onAppear {
      apiKey = cleanedStoredAPIKey()
      notificationSecret = KeychainSettingsStore.shared.paddleNotificationSecret
    }
    .onChange(of: apiKey) { _, newValue in
      saveNonEmptyPaddleAPIKey(newValue)
    }
    .onChange(of: notificationSecret) { _, newValue in
      saveNonEmptyNotificationSecret(newValue)
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

  private var paddleAPIBaseURL: String {
    switch settings.environment {
    case .sandbox:
      return "https://sandbox-api.paddle.com"
    case .production:
      return "https://api.paddle.com"
    }
  }

  private var discountPriceIDs: [String] {
    let allPriceIDs = [settings.defaultPriceID] + siteLicensePricing.tiers.map(\.priceID)

    return Array(
      Set(
        allPriceIDs
          .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
          .filter { !$0.isEmpty }
      )
    )
    .sorted()
  }

  private func cleanedStoredAPIKey() -> String {
    let storedAPIKey = KeychainSettingsStore.shared.paddleAPIKey

    guard storedAPIKey == "test_api_key_123" else {
      return storedAPIKey
    }

    KeychainSettingsStore.shared.remove(.paddleAPIKey)
    savedMessage = "Removed old test API key from Keychain."
    return ""
  }

  private func savePaddleAPIKey() {
    let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedAPIKey.isEmpty else {
      savedMessage = "API key was not saved because the field is blank."
      return
    }

    let result = KeychainSettingsStore.shared.save(trimmedAPIKey, for: .paddleAPIKey)

    guard result.didSave else {
      savedMessage = result.message
      return
    }

    guard KeychainSettingsStore.shared.paddleAPIKey == trimmedAPIKey else {
      savedMessage = "API key save could not be verified after writing to Keychain."
      return
    }

    apiKey = trimmedAPIKey
    savedMessage = "API key saved to Keychain."
  }

  private func saveNotificationSecret() {
    let trimmedSecret = notificationSecret.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedSecret.isEmpty else {
      savedMessage = "Notification secret was not saved because the field is blank."
      return
    }

    let result = KeychainSettingsStore.shared.save(trimmedSecret, for: .paddleNotificationSecret)

    guard result.didSave else {
      savedMessage = result.message
      return
    }

    guard KeychainSettingsStore.shared.paddleNotificationSecret == trimmedSecret else {
      savedMessage = "Notification secret save could not be verified after writing to Keychain."
      return
    }

    notificationSecret = trimmedSecret
    savedMessage = "Notification secret saved to Keychain."
  }

  private func saveNonEmptyPaddleAPIKey(_ value: String) {
    let trimmedAPIKey = value.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedAPIKey.isEmpty else {
      return
    }

    _ = KeychainSettingsStore.shared.save(trimmedAPIKey, for: .paddleAPIKey)
  }

  private func saveNonEmptyNotificationSecret(_ value: String) {
    let trimmedSecret = value.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedSecret.isEmpty else {
      return
    }

    _ = KeychainSettingsStore.shared.save(trimmedSecret, for: .paddleNotificationSecret)
  }

  private func copyCheckoutHTMLBlock() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(checkoutHTMLBlock, forType: .string)
    savedMessage = "Checkout HTML copied. Paste it over the existing pro.html purchase block, then sync public web files."
  }

  private func generateDiscountCodes() async {
    isGeneratingDiscountCodes = true
    discountCodeMessage = ""

    do {
      let generator = PaddleDiscountCodeGenerator(
        apiBaseURL: paddleAPIBaseURL,
        apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
      )
      let discounts = try await generator.generateTestCodes(
        count: discountCodeCount,
        environmentName: settings.environment.rawValue,
        restrictedPriceIDs: discountPriceIDs
      )
      let timestamp = Date().formatted(date: .abbreviated, time: .standard)
      let newLines = discounts.map { discount in
        "\(discount.code)  \(discount.id)  \(settings.environment.rawValue)  \(timestamp)"
      }
      let existing = generatedDiscountCodes.trimmingCharacters(in: .whitespacesAndNewlines)
      generatedDiscountCodes = ([existing] + newLines)
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
      discountCodeMessage = "Generated \(discounts.count) Paddle discount \(discounts.count == 1 ? "code" : "codes")."
    } catch {
      discountCodeMessage = error.localizedDescription
    }

    isGeneratingDiscountCodes = false
  }

  private func copyGeneratedDiscountCodes() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(generatedDiscountCodes, forType: .string)
    discountCodeMessage = "Stored discount codes copied."
  }

  private var checkoutHTMLBlock: String {
    let token = htmlAttribute(settings.clientSideToken)
    let defaultPriceID = htmlAttribute(defaultCheckoutPriceID)
    let baseUnitPrice = String(format: "%.2f", defaultBaseUnitPrice)
    let environmentLine = settings.environment == .sandbox
      ? "\n            data-paddle-environment=\"sandbox\""
      : ""
    let tierLines = siteLicensePricing.tiers
      .sorted { first, second in
        first.minimumSeats < second.minimumSeats
      }
      .map { tier in
        "            data-paddle-price-id-\(tier.attributeRangeLabel)=\"\(htmlAttribute(tier.priceID))\""
      }
      .joined(separator: "\n")

    return """
        <div class="hero-actions">
          <button
            class="button button-primary"
            id="buy-updock-pro"
            type="button"

            data-paddle-client-token="\(token)"
            data-paddle-price-id="\(defaultPriceID)"
            data-paddle-base-unit-price="\(baseUnitPrice)"
            data-paddle-currency="USD"
\(tierLines)\(environmentLine)
            data-paddle-success-url="https://updockapp.com/thanks.html"

          >
            Purchase UpDock Pro
          </button>
          <p class="checkout-status" id="buy-updock-pro-status" role="status" aria-live="polite"></p>
          <a class="button button-secondary" href="compare.html">Compare Versions</a>
        </div>
"""
  }

  private var defaultCheckoutPriceID: String {
    let savedDefaultPriceID = settings.defaultPriceID.trimmingCharacters(in: .whitespacesAndNewlines)

    if !savedDefaultPriceID.isEmpty {
      return savedDefaultPriceID
    }

    return siteLicensePricing.tiers
      .sorted { first, second in
        first.minimumSeats < second.minimumSeats
      }
      .first?
      .priceID ?? ""
  }

  private var defaultBaseUnitPrice: Double {
    siteLicensePricing.tiers
      .sorted { first, second in
        first.minimumSeats < second.minimumSeats
      }
      .first?
      .unitPrice ?? 19.99
  }

  private func htmlAttribute(_ value: String) -> String {
    value
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "&", with: "&amp;")
      .replacingOccurrences(of: "\"", with: "&quot;")
      .replacingOccurrences(of: "<", with: "&lt;")
      .replacingOccurrences(of: ">", with: "&gt;")
  }

  private func updateLocalPrivateConfig(constants: [String: String]) {
    if let configURL = savedLocalPrivateConfigURL() {
      updateLocalPrivateConfig(constants: constants, at: configURL, shouldRememberAccess: false)
      return
    }

    chooseAndUpdateLocalPrivateConfig(constants: constants)
  }

  private func chooseAndUpdateLocalPrivateConfig(constants: [String: String]) {
    let configDirectoryURL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Documents/GitHub/UpDockWebPage/updock-private")

    let panel = NSOpenPanel()
    panel.title = "Choose Private Config"
    panel.message = "Select paddle-config.php in updock-private."
    panel.prompt = "Update Config"
    panel.directoryURL = configDirectoryURL
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.allowsMultipleSelection = false
    if let phpType = UTType(filenameExtension: "php") {
      panel.allowedContentTypes = [phpType]
    }

    guard panel.runModal() == .OK, let configURL = panel.url else {
      savedMessage = "Local private config was not updated."
      return
    }

    updateLocalPrivateConfig(constants: constants, at: configURL, shouldRememberAccess: true)
  }

  private func updateLocalPrivateConfig(
    constants: [String: String],
    at configURL: URL,
    shouldRememberAccess: Bool
  ) {
    do {
      let didAccess = configURL.startAccessingSecurityScopedResource()
      defer {
        if didAccess {
          configURL.stopAccessingSecurityScopedResource()
        }
      }

      var config = try String(contentsOf: configURL, encoding: .utf8)
      var missingConstants: [String] = []

      for (name, value) in constants {
        let pattern = #"const\s+\#(name)\s*=\s*'[^']*';"#
        let escapedValue = value.replacingOccurrences(of: "'", with: "\\'")
        let replacement = "const \(name) = '\(escapedValue)';"

        guard config.range(of: pattern, options: .regularExpression) != nil else {
          missingConstants.append(name)
          continue
        }

        config = config.replacingOccurrences(
          of: pattern,
          with: replacement,
          options: .regularExpression
        )
      }

      guard missingConstants.isEmpty else {
        savedMessage = "Could not find \(missingConstants.joined(separator: ", ")) in local private config."
        return
      }

      try config.write(to: configURL, atomically: true, encoding: .utf8)

      if shouldRememberAccess {
        saveLocalPrivateConfigBookmark(for: configURL)
      }

      savedMessage = "Updated \(constants.keys.sorted().joined(separator: ", ")) in \(configURL.lastPathComponent). Sync it separately to the server."
    } catch {
      savedMessage = "Could not update local private config: \(error.localizedDescription)"
    }
  }

  private func savedLocalPrivateConfigURL() -> URL? {
    guard let encodedBookmark = UserDefaults.standard.string(forKey: paddlePrivateConfigBookmarkKey),
          let bookmarkData = Data(base64Encoded: encodedBookmark) else {
      return nil
    }

    do {
      var isStale = false
      let configURL = try URL(
        resolvingBookmarkData: bookmarkData,
        options: .withSecurityScope,
        relativeTo: nil,
        bookmarkDataIsStale: &isStale
      )

      if isStale {
        UserDefaults.standard.removeObject(forKey: paddlePrivateConfigBookmarkKey)
        return nil
      }

      return configURL
    } catch {
      UserDefaults.standard.removeObject(forKey: paddlePrivateConfigBookmarkKey)
      return nil
    }
  }

  private func saveLocalPrivateConfigBookmark(for configURL: URL) {
    do {
      let bookmarkData = try configURL.bookmarkData(
        options: .withSecurityScope,
        includingResourceValuesForKeys: nil,
        relativeTo: nil
      )
      UserDefaults.standard.set(
        bookmarkData.base64EncodedString(),
        forKey: paddlePrivateConfigBookmarkKey
      )
    } catch {
      savedMessage = "Updated \(configURL.lastPathComponent), but could not remember file access: \(error.localizedDescription)"
    }
  }
}

private struct PaddleDiscountCodeGenerator {
  var apiBaseURL: String
  var apiKey: String

  func generateTestCodes(
    count: Int,
    environmentName: String,
    restrictedPriceIDs: [String]
  ) async throws -> [PaddleCreatedDiscount] {
    guard !apiKey.isEmpty else {
      throw PaddleDiscountCodeError.missingAPIKey
    }

    guard !restrictedPriceIDs.isEmpty else {
      throw PaddleDiscountCodeError.missingPriceIDs
    }

    var discounts: [PaddleCreatedDiscount] = []

    for index in 1...count {
      let request = try makeCreateDiscountRequest(
        description: "UpDock \(environmentName) test discount \(index)",
        restrictedPriceIDs: restrictedPriceIDs
      )
      let (data, response) = try await URLSession.shared.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw PaddleDiscountCodeError.invalidResponse
      }

      guard (200...299).contains(httpResponse.statusCode) else {
        let errorResponse = try? JSONDecoder().decode(PaddleAPIErrorResponse.self, from: data)
        throw PaddleDiscountCodeError.apiError(
          statusCode: httpResponse.statusCode,
          detail: errorResponse?.error.detail ?? String(data: data, encoding: .utf8) ?? "Unknown Paddle API error"
        )
      }

      let decoded = try JSONDecoder().decode(PaddleCreateDiscountResponse.self, from: data)

      guard let code = decoded.data.code, !code.isEmpty else {
        throw PaddleDiscountCodeError.missingReturnedCode
      }

      discounts.append(
        PaddleCreatedDiscount(
          id: decoded.data.id,
          code: code
        )
      )
    }

    return discounts
  }

  private func makeCreateDiscountRequest(
    description: String,
    restrictedPriceIDs: [String]
  ) throws -> URLRequest {
    guard let url = URL(string: apiBaseURL + "/discounts") else {
      throw PaddleDiscountCodeError.invalidURL
    }

    let payload = PaddleCreateDiscountRequest(
      description: description,
      enabledForCheckout: true,
      type: "percentage",
      mode: "standard",
      amount: "100",
      recur: false,
      usageLimit: 1,
      restrictTo: restrictedPriceIDs,
      customData: [
        "created_by": "UpDock License Manager",
        "purpose": "test_checkout"
      ]
    )
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try encoder.encode(payload)

    return request
  }
}

private struct PaddleCreateDiscountRequest: Encodable {
  var description: String
  var enabledForCheckout: Bool
  var type: String
  var mode: String
  var amount: String
  var recur: Bool
  var usageLimit: Int
  var restrictTo: [String]
  var customData: [String: String]
}

private struct PaddleCreateDiscountResponse: Decodable {
  var data: PaddleDiscountResponseData
}

private struct PaddleDiscountResponseData: Decodable {
  var id: String
  var code: String?
}

private struct PaddleAPIErrorResponse: Decodable {
  var error: PaddleAPIErrorDetail
}

private struct PaddleAPIErrorDetail: Decodable {
  var detail: String
}

private struct PaddleCreatedDiscount: Hashable {
  var id: String
  var code: String
}

private enum PaddleDiscountCodeError: LocalizedError {
  case missingAPIKey
  case missingPriceIDs
  case invalidURL
  case invalidResponse
  case missingReturnedCode
  case apiError(statusCode: Int, detail: String)

  var errorDescription: String? {
    switch self {
    case .missingAPIKey:
      return "Save a Paddle API key before generating discount codes."
    case .missingPriceIDs:
      return "Configure at least one UpDock Pro price ID before generating restricted discount codes."
    case .invalidURL:
      return "The Paddle API URL is invalid."
    case .invalidResponse:
      return "Paddle returned an invalid response."
    case .missingReturnedCode:
      return "Paddle created a discount but did not return a checkout code."
    case .apiError(let statusCode, let detail):
      return "Paddle API returned HTTP \(statusCode): \(detail)"
    }
  }
}
