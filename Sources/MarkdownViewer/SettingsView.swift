import SwiftUI

/// Preferences window (⌘,). Holds the config needed for "Share as public link".
struct SettingsView: View {
    @ObservedObject private var settings = ShareSettings.shared

    var body: some View {
        Form {
            Section {
                TextField("Share site URL", text: $settings.baseURL, prompt: Text(ShareSettings.defaultBase))
                    .textFieldStyle(.roundedBorder)
                SecureField("API key (MD_SHARE_API_KEY)", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Sharing")
            } footer: {
                Text("Sharing posts the current document to \(settings.normalizedBase) and returns a public link (valid 30 days). The API key is stored in your Keychain, never in the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
        .frame(width: 460)
        .padding(.vertical, 4)
    }
}
