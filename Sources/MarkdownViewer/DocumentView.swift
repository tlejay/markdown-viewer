import SwiftUI
import AppKit
import MarkdownUI

/// The main reading surface: a scrollable, GitHub-styled render of the file.
///
/// Cold-start notes:
/// - `initialText` is already in memory (read synchronously by the document),
///   so the first frame renders immediately without touching disk again.
/// - The `FileWatcher` is created inside `.task`, i.e. *after* the first paint,
///   so live-reload setup never sits on the launch critical path.
struct DocumentView: View {
    let initialText: String
    let fileURL: URL?

    @ObservedObject private var settings = AppSettings.shared
    @State private var text: String
    @State private var watcher: FileWatcher?

    // Share state.
    @State private var isSharing = false
    @State private var sharedURL: URL?
    @State private var shareError: String?
    @State private var needsAPIKey = false

    init(initialText: String, fileURL: URL?) {
        self.initialText = initialText
        self.fileURL = fileURL
        _text = State(initialValue: initialText)
    }

    var body: some View {
        ScrollView {
            Markdown(text)
                .markdownTheme(.gitHub.text {
                    FontSize(.em(settings.fontScale))
                })
                .textSelection(.enabled)
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
                .frame(maxWidth: 860, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .preferredColorScheme(settings.appearance.colorScheme)
        .toolbar { toolbarContent }
        .task(id: fileURL) {
            guard let url = fileURL else { return }
            watcher = FileWatcher(url: url) {
                if let reloaded = try? String(contentsOf: url, encoding: .utf8) {
                    text = reloaded
                }
            }
        }
        .alert("Link copied", isPresented: Binding(get: { sharedURL != nil }, set: { if !$0 { sharedURL = nil } })) {
            Button("OK", role: .cancel) { sharedURL = nil }
            if let url = sharedURL {
                Button("Open in Browser") { NSWorkspace.shared.open(url); sharedURL = nil }
            }
        } message: {
            Text(sharedURL?.absoluteString ?? "")
        }
        .alert("Couldn't share", isPresented: Binding(get: { shareError != nil }, set: { if !$0 { shareError = nil } })) {
            Button("OK", role: .cancel) { shareError = nil }
        } message: {
            Text(shareError ?? "")
        }
        .alert("Set your API key", isPresented: $needsAPIKey) {
            Button("Open Settings") { openSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To create a public share link, paste your MD_SHARE_API_KEY in Settings.")
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                settings.zoomOut()
            } label: {
                Image(systemName: "textformat.size.smaller")
            }
            .help("Zoom Out (⌘−)")

            Button {
                settings.zoomReset()
            } label: {
                Text("\(Int((settings.fontScale * 100).rounded()))%")
                    .monospacedDigit()
                    .frame(minWidth: 40)
            }
            .help("Actual Size (⌘0)")

            Button {
                settings.zoomIn()
            } label: {
                Image(systemName: "textformat.size.larger")
            }
            .help("Zoom In (⌘+)")

            Menu {
                Picker("Appearance", selection: $settings.appearance) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Image(systemName: "circle.lefthalf.filled")
            }
            .help("Appearance")

            Button {
                share()
            } label: {
                if isSharing {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .disabled(isSharing)
            .help("Share as public link")
        }
    }

    private func share() {
        guard ShareSettings.shared.isConfigured else {
            needsAPIKey = true
            return
        }
        isSharing = true
        let markdown = text
        Task {
            do {
                let url = try await ShareService.share(markdown: markdown)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(url.absoluteString, forType: .string)
                NSWorkspace.shared.open(url)
                sharedURL = url
            } catch {
                shareError = error.localizedDescription
            }
            isSharing = false
        }
    }

    /// Opens the Settings window across macOS versions (the selector was
    /// renamed from `showPreferencesWindow:` to `showSettingsWindow:` in 14).
    private func openSettings() {
        if NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) { return }
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
