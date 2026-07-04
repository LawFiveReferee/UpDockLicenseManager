import SwiftUI

struct PaddleSettingsView: View {
    @State private var settings = PaddleSettings()
    
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
                
                Text(
                    "Used to verify Paddle webhook signatures."
                )
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            
            apiKey =
            KeychainSettingsStore.shared.paddleAPIKey
            
            notificationSecret =
            KeychainSettingsStore.shared
                .paddleNotificationSecret
        }
    }
}
