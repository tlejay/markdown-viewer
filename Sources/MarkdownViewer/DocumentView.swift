import SwiftUI
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
        }
    }
}
