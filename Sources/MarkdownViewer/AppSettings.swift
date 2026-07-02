import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

/// App-wide view preferences, persisted to `UserDefaults`.
///
/// A single shared instance so the menu-bar commands and every document window
/// stay in sync. Reading defaults is negligible, so constructing this eagerly
/// does not affect launch time.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    static let minScale = 0.6
    static let maxScale = 2.6
    private static let step = 0.1

    @Published var fontScale: Double {
        didSet { defaults.set(fontScale, forKey: "fontScale") }
    }

    @Published var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: "appearance") }
    }

    private let defaults = UserDefaults.standard

    private init() {
        let stored = defaults.object(forKey: "fontScale") as? Double ?? 1.0
        fontScale = min(Self.maxScale, max(Self.minScale, stored))
        appearance = AppearanceMode(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
    }

    func zoomIn() { fontScale = min(Self.maxScale, fontScale + Self.step) }
    func zoomOut() { fontScale = max(Self.minScale, fontScale - Self.step) }
    func zoomReset() { fontScale = 1.0 }
}
