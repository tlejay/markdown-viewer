import SwiftUI

/// Settings for the "Share as public link" feature.
///
/// `baseURL` is a plain preference (defaults to the production site). `apiKey`
/// is a secret and is persisted to the Keychain, not UserDefaults.
final class ShareSettings: ObservableObject {
    static let shared = ShareSettings()

    static let defaultBase = "https://kit.madebytle.com"
    private static let baseKey = "shareBaseURL"
    private static let keyAccount = "md-share-api-key"

    private let defaults = UserDefaults.standard

    @Published var baseURL: String {
        didSet { defaults.set(baseURL, forKey: Self.baseKey) }
    }

    @Published var apiKey: String {
        didSet {
            let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                Keychain.delete(Self.keyAccount)
            } else {
                Keychain.set(trimmed, for: Self.keyAccount)
            }
        }
    }

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// `baseURL` with any trailing slash removed.
    var normalizedBase: String {
        var b = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while b.hasSuffix("/") { b.removeLast() }
        return b.isEmpty ? Self.defaultBase : b
    }

    private init() {
        baseURL = defaults.string(forKey: Self.baseKey) ?? Self.defaultBase
        apiKey = Keychain.get(Self.keyAccount) ?? ""
    }
}
