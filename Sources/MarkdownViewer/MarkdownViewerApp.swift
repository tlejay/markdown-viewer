import SwiftUI

@main
struct MarkdownViewerApp: App {
    // Held here so the shared settings object lives for the whole app session.
    @StateObject private var settings = AppSettings.shared

    var body: some Scene {
        // A viewing-only DocumentGroup gives us, for free: opening files from
        // Finder's "Open With", multiple windows, native window tabs, and the
        // recent-files menu — all the multi-file behaviour we want, with no
        // custom window management.
        DocumentGroup(viewing: MarkdownDocument.self) { config in
            DocumentView(initialText: config.document.text, fileURL: config.fileURL)
        }
        .commands { ViewerCommands() }
    }
}

/// Menu-bar commands for zoom and appearance. Bound to the shared settings so
/// the shortcuts work regardless of which window is focused.
struct ViewerCommands: Commands {
    @ObservedObject private var settings = AppSettings.shared

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Button("Zoom In") { settings.zoomIn() }
                .keyboardShortcut("+", modifiers: .command)
            Button("Zoom Out") { settings.zoomOut() }
                .keyboardShortcut("-", modifiers: .command)
            Button("Actual Size") { settings.zoomReset() }
                .keyboardShortcut("0", modifiers: .command)

            Divider()

            Picker("Appearance", selection: $settings.appearance) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
        }
    }
}
